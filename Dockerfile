# First development base. Pin the multi-platform upstream manifest digest.
ARG BASE_IMAGE=mcr.microsoft.com/devcontainers/cpp:3-trixie@sha256:06e59c756f0b90728dd87e4b96cb93d923a6c7863d580976363fb492f77ba001
FROM ${BASE_IMAGE}

USER 0:0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PLAYWRIGHT_BROWSERS_PATH=/opt/playwright-browsers

ARG TARGETARCH
ARG GO_VERSION=1.27.1
ARG NODE_VERSION=24.21.0
ARG GRADLE_VERSION=9.1.0
ARG RUST_VERSION=1.99.0
ARG TYPESCRIPT_VERSION=7.0.2
ARG PLAYWRIGHT_VERSION=1.63.0
ARG BUN_VERSION=1.4.2
ARG PNPM_VERSION=10.18.3
ARG YQ_VERSION=4.54.1

# Debian supplies the general CLIs and build dependencies on both supported architectures.
# Package versions are recorded by the smoke test; release builds pin the base and image digest.
RUN apt-get update && apt-get install -y --no-install-recommends \
      apt-transport-https awscli bash ca-certificates chromium curl fd-find git git-lfs \
      gnupg gh jq libatomic1 libssl-dev lsof maven netcat-openbsd ninja-build \
      openssh-client openssl pipx pkg-config procps python3 python3-pip python3-venv \
      ripgrep rsync shellcheck sqlite3 sudo tar tree unzip wget xz-utils zip zlib1g-dev \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && rm -rf /var/lib/apt/lists/*

# The Paperclip harness expects mikefarah/yq scalar output, not Debian's jq wrapper.
# SHA-256 values are from the v4.54.1 release checksums asset.
RUN case "${TARGETARCH}" in \
      amd64) yq_sha=8e34fc298390875de416e6a4afcb8cabeceb25d9aa8506c1a2f9353cf702ea5f ;; \
      arm64) yq_sha=189088da0c6429ec5178dfaab1a114805f6cab0b61b165ab236efedf1d57a71b ;; \
      *) exit 1 ;; \
    esac \
    && curl -fsSLo /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" \
    && echo "${yq_sha}  /usr/local/bin/yq" | sha256sum -c - \
    && chmod +x /usr/local/bin/yq

# Node's published checksum protects the architecture-specific archive.
RUN case "${TARGETARCH}" in amd64) node_arch=x64 ;; arm64) node_arch=arm64 ;; *) exit 1 ;; esac \
    && curl -fsSLo /tmp/node.tar.xz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${node_arch}.tar.xz" \
    && curl -fsSLo /tmp/node-shasums "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt" \
    && grep " node-v${NODE_VERSION}-linux-${node_arch}.tar.xz$" /tmp/node-shasums \
         | sed 's@node-v[^ ]*\.tar.xz@/tmp/node.tar.xz@' | sha256sum -c - \
    && tar -xJf /tmp/node.tar.xz --strip-components=1 -C /usr/local \
    && rm /tmp/node.tar.xz /tmp/node-shasums

# These Go checksums are published at https://go.dev/dl/.
RUN case "${TARGETARCH}" in \
      amd64) go_sha=63d339f0da5ab53635a56f2490a7984dfe12dfcff22ad749f63edaf590168445 ;; \
      arm64) go_sha=3450b45a3f9ee8568792736a5c5e70a1f2e9b36c35a8f74958c03e51d7d92bec ;; \
      *) exit 1 ;; \
    esac \
    && curl -fsSLo /tmp/go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" \
    && echo "${go_sha}  /tmp/go.tar.gz" | sha256sum -c - \
    && rm -rf /usr/local/go \
    && tar -xzf /tmp/go.tar.gz -C /usr/local \
    && rm /tmp/go.tar.gz

# Official Adoptium and Microsoft Debian feeds supply Java 25 and .NET 10 for amd64/arm64.
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
      | gpg --dearmor -o /usr/share/keyrings/adoptium.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb trixie main" \
      > /etc/apt/sources.list.d/adoptium.list \
    && curl -fsSLo /tmp/packages-microsoft-prod.deb \
      https://packages.microsoft.com/config/debian/13/packages-microsoft-prod.deb \
    && dpkg -i /tmp/packages-microsoft-prod.deb \
    && rm /tmp/packages-microsoft-prod.deb \
    && apt-get update \
    && apt-get install -y --no-install-recommends temurin-25-jdk dotnet-sdk-10.0 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s "$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" /opt/java
ENV JAVA_HOME=/opt/java

# Debian's Gradle 4.x cannot run on JDK 25; use a Java-25-compatible release.
RUN curl -fsSLo /tmp/gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    && curl -fsSLo /tmp/gradle.sha256 "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip.sha256" \
    && echo "$(cat /tmp/gradle.sha256)  /tmp/gradle.zip" | sha256sum -c - \
    && unzip -q /tmp/gradle.zip -d /opt \
    && ln -s "/opt/gradle-${GRADLE_VERSION}" /opt/gradle \
    && rm /tmp/gradle.zip /tmp/gradle.sha256

ENV PATH="/usr/local/go/bin:/opt/gradle/bin:/home/vscode/.cargo/bin:/home/vscode/.bun/bin:/home/vscode/.local/bin:${PATH}" \
    NODE_PATH=/usr/local/lib/node_modules

RUN npm install -g \
      "typescript@${TYPESCRIPT_VERSION}" "pnpm@${PNPM_VERSION}" \
      "bun@${BUN_VERSION}" "@playwright/test@${PLAYWRIGHT_VERSION}" \
    && playwright install --with-deps chromium \
    && chmod -R a+rX /opt/playwright-browsers

# Keep toolchain managers and package caches writable by the runtime user.
RUN runuser -u vscode -- bash -c \
      "curl -fsSLo /tmp/rustup-init.sh https://sh.rustup.rs && sh /tmp/rustup-init.sh -y --profile minimal --default-toolchain ${RUST_VERSION} && rm /tmp/rustup-init.sh" \
    && runuser -u vscode -- pipx install uv \
    && mkdir -p /workspace /home/vscode/.cache \
    && chown -R vscode:vscode /workspace /home/vscode/.cache \
    && chmod 700 /home/vscode

ENV NPM_CONFIG_PREFIX=/home/vscode/.local
WORKDIR /workspace
USER 1000:1000
CMD ["/bin/bash"]
