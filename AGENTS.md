# AGENTS.md

Rules for AI agents and human contributors working in this repository.

## Project summary

`agent-team-ready-container` will build and publish a general development base image for the agentic-teams set. Its intended toolchains are C++23, Rust, Go, Java 25, Python, C#, and TypeScript 7, plus common CLIs, package managers, Playwright and a compatible Chrome browser. `agentic-team-w-paperclip` will consume this base and remains responsible for Hermes, OMP, OpenCode and Paperclip.

**Current status:** documentation scaffold only. No Dockerfile, CI, image or PRD exists yet. Do not describe an intended tool as installed or tested. Read [INTENT.md](INTENT.md) for the purpose and scope before designing the image.

## Documentation routing

| Change | Home |
|---|---|
| Purpose, goals or scope boundary | `INTENT.md` |
| Detailed requirements and acceptance criteria | The PRD, once created under `specs/` |
| Architectural decisions and implementation notes | `docs/`, when needed |
| Build, configuration and use instructions | `user-docs/`, when a usable image exists |
| Newcomer orientation and actual status | `README.md` |
| Contributor rules | `AGENTS.md` |

Keep claims about shipped tools and supported architectures tied to build or runtime evidence. Do not copy the harness repository's documentation into this one; link to the owning repository.

## Repository boundary

- Make and commit base-image changes here, never in the documentation-only `agentic-teams` root.
- Make changes to Hermes, OMP, OpenCode, Paperclip, their entrypoints and their configuration in `agentic-team-w-paperclip`.
- Keep the base independent of deployment-specific identities, credentials and tenant settings. Never commit tokens, keys, passwords or real tenant identifiers.
- Do not give the runtime user unrestricted root or host access merely to support package installation. Define and test the allowed runtime installation path in the PRD.

## Engineering expectations for the future image

- Build and test both `linux/amd64` and `linux/arm64`; the current consumer publishes both.
- Run the final image as a non-root user. Verify ownership, writable caches, and tools on `PATH` after the privilege drop.
- Verify representative compilation or execution for every advertised language, including a C++23 feature and the declared TypeScript major version. Verify Playwright can launch the installed browser.
- Pin or record upstream image and tool versions so a rebuild is explainable. Do not silently rely on an installer changing what it supplies.
- Keep OS package installation at build time unless the PRD explicitly defines a constrained runtime mechanism. Do not assume `apt` or another system package manager works for the unprivileged agent.
- Test the derived harness images before declaring a new base compatible with them.

These are design constraints, not claims that implementation or tests already exist. The PRD will specify concrete commands and release gates.

## Git

- Use short, imperative commit messages. Do not force-push `main`.
- Do not commit generated binaries, browser downloads, package caches, `.env` files or local state.
- Keep this repository independent: no submodule or vendored copy of another agentic-teams repository.
