FROM debian:trixie-slim

# System packages for development workflows
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    openssh-client \
    jq \
    ripgrep \
    build-essential \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code via official installer
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && cp /root/.local/bin/claude /usr/local/bin/claude \
    && cp -r /root/.local/share/claude /usr/local/share/claude \
    && rm -rf /root/.local/bin/claude /root/.local/share/claude

# Non-root user with configurable UID/GID to match host
ARG USER_UID=1000
ARG USER_GID=1000
RUN (getent group ${USER_GID} || groupadd --gid ${USER_GID} claude) \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m claude \
    && mkdir -p /home/claude/.claude \
    && chown -R ${USER_UID}:${USER_GID} /home/claude

# Git safe directory for mounted volumes
RUN git config --system --add safe.directory '*'

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENV DISABLE_AUTOUPDATER=1
ENV CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

USER claude
WORKDIR /home/claude

ENTRYPOINT ["entrypoint.sh"]
