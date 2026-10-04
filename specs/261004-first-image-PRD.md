# First development base image PRD

**Status:** implementation draft. The [latest native CI run](https://github.com/stainedhead/agent-team-ready-container/actions/runs/37219853532) passed build, package-install and sandboxed browser smoke tests on amd64 and arm64. This document defines the remaining release gates; passing them is required before the image or skill can claim a released, verified tool inventory.

## Purpose and boundary

Ship a reusable Linux development base for the agentic-teams harness images. This repository owns language toolchains, general development CLIs, package managers, and browser binaries. The harness repository owns Hermes, OMP, OpenCode, Paperclip, entrypoints, and credential integration.

## Decisions

1. Derive from `mcr.microsoft.com/devcontainers/cpp:3-trixie`. It supplies the C++ toolchain, vcpkg, and a UID 1000 `vscode` user. The Dockerfile pins the multi-platform manifest digest `sha256:06e59c756f0b90728dd87e4b96cb93d923a6c7863d580976363fb492f77ba001`; record the resolved per-architecture digests in release evidence.
2. The runtime user is UID/GID 1000. Language package managers install project dependencies as that user. Their caches and user bin directories must be writable. `sudo apt-get` is available for task-specific Debian packages inside a disposable container. This grants root **inside that container**; deployment must not mount the host Docker socket, host credentials, or broad host directories. A task's OS additions live only as long as its container unless an owner bakes them into a derived image.
3. Include Playwright's matching Chromium browser for application tests and Debian Chromium as a general browser command. Playwright 1.63 supports a Chrome for Testing Chromium build on Linux Arm64 as well as amd64. External-site research uses a separate browser container built from this image with no workspace or credentials mounted. The browser sandbox and deployment profile must pass an explicit integration gate before external-site research is described as safe.
4. Build native `linux/amd64` and `linux/arm64` variants. Validate both architectures as UID 1000 and publish only after both pass. The first implementation PR runs CI builds but does not publish an image.
5. The image has no harness entrypoint. Derived harness images retain their own startup logic. A separate harness change will switch its `FROM` after the base has passed smoke tests.

## Included tools

| Area | First image | Verification |
|---|---|---|
| C++23 | Base GCC/Clang, make, CMake, vcpkg; add Ninja and common build headers | Compile and run a C++23 program |
| Rust | `rustup`, `rustc`, `cargo` | Build and run a Cargo project as UID 1000 |
| Go | Go 1.27.1 | Build and run a Go module as UID 1000 |
| Java | Temurin JDK 25, Maven, Gradle | Compile and run Java 25; verify build tools |
| Python | Debian Python 3, `venv`, `pip`, `pipx`, `uv` | Create a venv and install a package as UID 1000 |
| C# | .NET SDK 10 | Create and run a console project as UID 1000 |
| JavaScript / TypeScript | Node 24, npm, pnpm, Bun 1.4.2, TypeScript 7 | Add a dependency with Bun and compile TypeScript |
| Common CLI | `git`, `gh`, `aws`, `curl`, `wget`, `jq`, mikefarah/yq 4.54.1, `rg`, `fd`, SSH client, archive and diagnostic tools | Find each command and print its version; check `yq` scalar output for harness compatibility |
| Browser | Chromium and Playwright 1.63 with its matching Chromium download | Launch browser as UID 1000 and load a local page |

Version numbers above are initial build inputs. CI records the resolved versions. Package repository updates may change minor versions; a release must pin or lock inputs and record image digests. Homebrew is not included on Linux: Debian `apt` supplies system packages and the language package managers supply project packages.

## Runtime installation behavior

- Project dependency examples must pass for npm, pnpm, Bun, Cargo, Go modules, Python venv/uv, Maven or Gradle, and NuGet, without writing outside the task workspace or the agent's home.
- `sudo apt-get update && sudo apt-get install -y <package>` must work in a disposable task container. The runtime image's sudo capability is not a host privilege boundary. Never mount a Docker socket or sensitive host files into that container.
- An agent should record any added OS package in the project's Dockerfile or setup instructions when the change must persist. The root skill will distinguish preinstalled tools from task-installed tools and explain this persistence rule.

## Browser behavior

- App tests use Playwright with the browser version bundled for that Playwright release. A project may install its own Playwright dependency; it must install the matching browser version if it differs from the image's version.
- External research runs in a separate browser container with no credentials or workspace mount. Deployment supplies a restricted network connection to that service and a browser seccomp profile that permits the browser sandbox. Do not put the credential daemon socket or cloud metadata access in the browser container.
- The browser research path is release-blocked until a test proves the browser sandbox is active on each deployment target and an external page cannot read agent files or environment variables.

## Acceptance gates

1. Dockerfile lint and shell syntax checks pass.
2. Native amd64 and arm64 CI each build the image and run the smoke script as UID 1000. The script exercises representative code for every language, checks CLI versions, writes to package caches, and launches a local Playwright page.
3. A package-install smoke test adds Bun, Python, Rust, and apt dependencies in an ephemeral container and confirms an unprivileged user can use them.
4. The harness and Paperclip images build from a digest-pinned version of the new base. Their existing smoke suite passes on both architectures, including their entrypoints and UID assumptions.
5. The separate browser research deployment passes isolation and sandbox checks on local macOS container and AWS targets.
6. The owning repository opens a pull request to update `agentic-teams/skills/agent-team-ready-container.md` with the verified inventory and installation commands. The status banner stays until a released image and its examples have been tested.

Gates 1–3 passed in native CI on both architectures. The same CI run also launched Chromium with `chromiumSandbox: true` and confirmed a renderer entered a separate Linux user namespace under the version-matched Playwright seccomp profile. A local macOS ARM64 container reached `https://example.com` without an agent workspace or credentials mounted. Gate 5 still needs the actual research service and AWS deployment checks. Gate 4 remains open; the gate 6 [root skill PR](https://github.com/stainedhead/agentic-teams/pull/3) is open for review. No image has been published.

## First implementation scope

This PR may establish the Dockerfile, CI, and smoke tests before all release gates pass. It must say which gates remain open. It must not publish a `latest` tag or claim that external-site browsing is isolated merely because Chromium is installed.
