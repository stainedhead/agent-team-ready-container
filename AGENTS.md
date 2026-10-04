# AGENTS.md

Rules for AI agents and human contributors working in this repository.

## Project summary

`agent-team-ready-container` will build and publish a general development base image for the agentic-teams set. Its intended toolchains are C++23, Rust, Go, Java 25, Python, C#, and TypeScript 7, plus common CLIs, package managers (including Bun), Playwright and a compatible Chrome browser. `agentic-team-w-paperclip` will consume this base and remains responsible for Hermes, OMP, OpenCode and Paperclip.

**Current status:** first image implementation in progress. The Dockerfile, CI smoke tests and [first-image PRD](specs/261004-first-image-PRD.md) exist. The [first native CI build](https://github.com/stainedhead/agent-team-ready-container/actions/runs/37215901006) passed on amd64 and arm64, but no image is published and the harness/browser deployment gates remain open. Describe only the tools exercised by that CI run as verified in a CI-built image. Read [INTENT.md](INTENT.md) for the purpose and scope.

## Documentation routing

| Change | Home |
|---|---|
| Purpose, goals or scope boundary | `INTENT.md` |
| Detailed requirements and acceptance criteria | `specs/261004-first-image-PRD.md` |
| Architectural decisions and implementation notes | `docs/`, when needed |
| Build, configuration and use instructions | `user-docs/`, when a usable image exists |
| Newcomer orientation and actual status | `README.md` |
| Contributor rules | `AGENTS.md` |

Keep claims about shipped tools and supported architectures tied to build or runtime evidence. Do not copy the harness repository's documentation into this one; link to the owning repository.

## Repository boundary

- Make and commit base-image changes here, never in the documentation-only `agentic-teams` root.
- Make changes to Hermes, OMP, OpenCode, Paperclip, their entrypoints and their configuration in `agentic-team-w-paperclip`.
- Keep the base independent of deployment-specific identities, credentials and tenant settings. Never commit tokens, keys, passwords or real tenant identifiers.
- Publish the agent-facing skill to `agentic-teams/skills/agent-team-ready-container.md` through a pull request to the root repository, following the same manual skill-publication process as the other tool repositories. Do not keep a copy here. Its initial status-marked draft is proposed in the root repository; open a root skill PR in the same change cycle as changes to the tool inventory, package installation paths or browser usage. Keep its status banner until a released image and its examples have been verified.
- Agents must be able to install open-source project dependencies, test frameworks and task-specific tools while running. Do not give the runtime user unrestricted host access merely to support installation. Define and test both user-level and system-package installation paths in the PRD.

## Engineering expectations for the future image

- Build and test both `linux/amd64` and `linux/arm64`; the current consumer publishes both.
- Run the final image as a non-root user. Verify ownership, writable caches, and tools on `PATH` after the privilege drop.
- Verify representative compilation or execution for every advertised language, including a C++23 feature and the declared TypeScript major version. Verify Playwright can launch the installed browser.
- Verify `bun add --dev` can add a development dependency as the unprivileged agent on both supported architectures, and that its cache and executable path are writable and reachable.
- Verify browser use for both application tests and external research. External sites are untrusted; the browser process must not inherit agent credentials or gain access to unrelated agent data. Test the browser sandbox on each deployment target.
- Pin or record upstream image and tool versions so a rebuild is explainable. Do not silently rely on an installer changing what it supplies.
- Define a workable runtime path for dependencies that need OS packages, as well as user-level package managers. Do not assume `apt` or another system package manager works for the unprivileged agent.
- Test the derived harness images before declaring a new base compatible with them.

These are design constraints, not claims that implementation or tests already exist. The PRD will specify concrete commands and release gates.

## Git

- Use short, imperative commit messages. Do not force-push `main`.
- Do not commit generated binaries, browser downloads, package caches, `.env` files or local state.
- Keep this repository independent: no submodule or vendored copy of another agentic-teams repository.
