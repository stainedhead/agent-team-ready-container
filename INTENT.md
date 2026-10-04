# Intent

## Purpose

Provide a reusable development container base for the [agentic-teams](https://github.com/stainedhead/agentic-teams) set. An agent should start with the common tools needed to inspect, build, test and change software, rather than spend its first task assembling a toolchain.

This repository owns the development toolchain layer. [agentic-team-w-paperclip](https://github.com/stainedhead/agentic-team-w-paperclip) owns the Hermes, OMP, OpenCode and Paperclip images that will consume it. The base should be useful to other agent runtimes as well.

**Status:** repository scaffold only. No image, published artifact or verified toolchain exists yet. The PRD will define the exact versions, installation methods, supported architectures and release criteria.

## Goals

- **Start ready for polyglot development.** Include working C++23, Rust, Go, Java 25, Python, C#, and TypeScript 7 toolchains, with their normal build and package managers. Include Bun alongside npm and pnpm for JavaScript and TypeScript projects.
- **Include common agent tools.** Provide `git`, `gh`, `aws`, and other general development utilities needed by the harness images. Include Playwright and a compatible Chrome browser for application testing and research on external sites.
- **Allow additions during a task.** An agent must be able to install open-source project dependencies, test frameworks and tools needed to complete its work. Provide working package managers, writable caches and an installation path for dependencies that require system packages. The PRD must define how these additions persist and how system-level installation works without granting unrestricted host access.
- **Work where the current images work.** Preserve Linux `amd64` and `arm64` builds for local Apple Silicon and AWS deployment, and run the agent as an unprivileged user.
- **Be reproducible and verifiable.** Pin or otherwise control the base and tool versions, test the actual command paths and representative builds on both architectures, and publish images with clear provenance.
- **Isolate external browsing.** Let agents research public sites while keeping browser processes and visited content away from credentials and other agent data. Verify the browser's sandbox in each deployment target.

## Starting direction

Evaluate Microsoft's multi-architecture C++ development image (`mcr.microsoft.com/devcontainers/cpp:3-trixie`) as the starting layer, then add the missing toolchains and utilities. This is a candidate, not an adopted dependency; the PRD and build validation must confirm C++23 support, compatibility with the harness installers, browser availability, image size and update strategy.

Linux uses its distribution package manager for system packages. Homebrew is not currently a requirement for the image; the PRD should decide whether any capability actually requires it.

## Non-goals

- Implementing or configuring an agent harness or Paperclip. Those belong in `agentic-team-w-paperclip`.
- Installing an agent's credentials or changing the credential model. Identity and short-lived credentials belong to `agent-okta-d` and the deployment environment.
- Defining the requirements of every project an agent might edit. Projects can add their own dependencies and versions on top of this base.
- Deploying a fleet or granting agents unrestricted host privileges.

## How this file is used

`INTENT.md` records why this repository exists and where its responsibility ends. Put detailed behavior, version choices and acceptance tests in the PRD when it is written; update this file when the purpose or scope changes.
