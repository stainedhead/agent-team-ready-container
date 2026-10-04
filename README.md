# agent-team-ready-container

Development base image planned for the [agentic-teams](https://github.com/stainedhead/agentic-teams) set. It will supply common language toolchains, development CLIs, package managers and browser automation. The [agentic-team-w-paperclip](https://github.com/stainedhead/agentic-team-w-paperclip) images are the intended first consumers and will continue to own the harnesses and Paperclip.

**Status: planning scaffold.** There is no Dockerfile or published image yet. The next step is a PRD covering exact versions, installation and update choices, browser isolation for external research, runtime package installation, architecture support, test gates and integration with the current images.

Read [INTENT.md](INTENT.md) for the purpose and scope, then [AGENTS.md](AGENTS.md) for contributor rules.
The planned agent skill at `agentic-teams/skills/agent-team-ready-container.md` will document the verified tool inventory and runtime installation paths when an image is released.
