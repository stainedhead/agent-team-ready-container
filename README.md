# agent-team-ready-container

Development base image planned for the [agentic-teams](https://github.com/stainedhead/agentic-teams) set. It will supply common language toolchains, development CLIs, package managers and browser automation. The [agentic-team-w-paperclip](https://github.com/stainedhead/agentic-team-w-paperclip) images are the intended first consumers and will continue to own the harnesses and Paperclip.

**Status: first image under development.** The [first-image PRD](specs/261004-first-image-PRD.md), Dockerfile and native `amd64`/`arm64` CI smoke tests are present. Both architectures passed the [first full CI build](https://github.com/stainedhead/agent-team-ready-container/actions/runs/37215901006), including language, browser and runtime package-install checks. No image is published yet. The current Paperclip images still use their own Debian base.

Read [INTENT.md](INTENT.md) for the purpose and scope, then [AGENTS.md](AGENTS.md) for contributor rules.
The planned agent skill at `agentic-teams/skills/agent-team-ready-container.md` will document the verified tool inventory and runtime installation paths when an image is released. Skill changes are published through pull requests to the root repository, following the other tool repositories' process.

## Try the first image locally

```bash
docker build -t agent-team-ready-container:dev .
docker run --rm --ipc=host -v "$PWD/tests:/tests:ro" agent-team-ready-container:dev bash /tests/smoke.sh
```

The image starts as UID/GID 1000 in `/workspace`. It has no harness entrypoint. Common project package managers write to that user's workspace or home. For task-specific Debian packages, use `sudo apt-get` inside a disposable task container. Such additions disappear with the container unless the image is rebuilt; do not mount a host Docker socket or credentials into an install-capable task container.

Use Playwright's bundled Chromium for application tests. External-site research requires a separate browser container without agent files or credentials, plus a verified browser sandbox. That deployment path is an open release gate; the installed browser alone does not establish it. See the [PRD](specs/261004-first-image-PRD.md) for the full release criteria.
