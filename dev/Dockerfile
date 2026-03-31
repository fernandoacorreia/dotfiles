FROM mcr.microsoft.com/devcontainers/base:trixie

ARG HOST_UID=1000
ARG HOST_GID=1000

# build-essential, sudo, curl, git, zsh already in base image.
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps python3 file \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Remap the built-in 'vscode' user/group to match the host user's UID/GID so that files
# written inside the container are owned by the correct user on the host filesystem.
# If the target GID is already taken (e.g. macOS GID 20 = dialout in Debian), reuse it.
RUN if getent group "${HOST_GID}" >/dev/null; then \
        usermod -u "${HOST_UID}" -g "${HOST_GID}" vscode; \
    else \
        groupmod -g "${HOST_GID}" vscode; \
        usermod -u "${HOST_UID}" -g "${HOST_GID}" vscode; \
    fi && \
    chown -R vscode:vscode /home/vscode

# Always true inside the container; absent on the host. Use to gate container-only behavior.
# Also controls dotfiles setup: skips SSH keys, repo clone, and ansible password prompt.
ENV IN_CONTAINER=true

USER vscode
RUN mkdir -p /home/vscode/.ssh
WORKDIR /home/vscode
