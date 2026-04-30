#!/bin/bash
# Customizable per-user provisioning. Runs once during scripts/create.sh,
# and any time you call scripts/reprovision.sh. Idempotent: safe to re-run.
#
# Initial stub installs Docker only. Add your own tools below.

set -euo pipefail

# ---------- Docker ----------
if ! command -v docker >/dev/null 2>&1; then
    echo "==> Installing Docker"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    codename="$(lsb_release -cs)"
    echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
        | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

    sudo apt-get update -y
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin

    sudo usermod -aG docker "$USER"
    echo "==> Docker installed. New shells will have docker group membership."
else
    echo "==> Docker already installed, skipping"
fi

# ---------- Add your own setup below ----------
# Examples:
#   sudo apt-get install -y build-essential pkg-config
#   curl -fsSL https://get.pnpm.io/install.sh | sh -
#   curl -fsSL https://astral.sh/uv/install.sh | sh

# ---------- Optional user hook from the host ----------
# If the Mac has ~/dev-vm-shared/dev-vm-setup.sh, run it here. The host's
# ~/dev-vm-shared is mounted into the VM at the same home-relative path
# (~/dev-vm-shared). This lets you keep machine-specific or private setup
# outside this repo.
HOOK="${HOME}/dev-vm-shared/dev-vm-setup.sh"
if [ -f "${HOOK}" ]; then
    echo "==> Running user hook: ${HOOK}"
    bash "${HOOK}"
else
    echo "==> No user hook at ${HOOK}, skipping"
fi
