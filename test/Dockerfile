FROM debian:trixie

ARG HOST_UID=1000
ARG HOST_GID=1000

RUN apt-get update && apt-get install -y \
    sudo curl git build-essential procps python3 file zsh \
    && rm -rf /var/lib/apt/lists/*

# Create user with host uid/gid. If the GID already exists (e.g. macOS GID 20
# maps to Debian's "dialout"), reuse that group instead of creating a new one.
RUN if getent group ${HOST_GID} >/dev/null 2>&1; then \
      GROUP_NAME=$(getent group ${HOST_GID} | cut -d: -f1); \
    else \
      GROUP_NAME=tester; \
      groupadd -g ${HOST_GID} ${GROUP_NAME}; \
    fi && \
    useradd -m -u ${HOST_UID} -g ${HOST_GID} -s /bin/bash tester && \
    echo 'tester ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

USER tester
RUN mkdir -p /home/tester/.ssh
WORKDIR /home/tester
