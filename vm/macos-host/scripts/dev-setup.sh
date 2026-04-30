#!/bin/bash
# Customizable per-user provisioning. Runs once during scripts/create.sh,
# and any time you call scripts/reprovision.sh. Idempotent: safe to re-run.
#
# Initial stub installs Docker only. Add your own tools below.

set -euo pipefail

# ---------- Disable unattended-upgrades ----------
# Disables the service AND the apt-daily timers that schedule it. Just
# disabling unattended-upgrades.service alone leaves the timers running,
# which is the actual source of "Could not get apt lock" errors.
for unit in unattended-upgrades.service apt-daily.timer apt-daily-upgrade.timer; do
    if systemctl is-enabled --quiet "${unit}" 2>/dev/null; then
        echo "==> Disabling ${unit}"
        sudo systemctl disable --now "${unit}"
    fi
done

# ---------- System updates ----------
echo "==> Updating system packages"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

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

# ---------- Docker daemon config (log rotation) ----------
# Without this, json-file logs grow unbounded and can fill the disk.
DAEMON_JSON=/etc/docker/daemon.json
read -r -d '' DESIRED_DAEMON_JSON <<'EOF' || true
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
if ! sudo test -f "${DAEMON_JSON}" \
   || ! echo "${DESIRED_DAEMON_JSON}" | sudo cmp -s - "${DAEMON_JSON}"; then
    echo "==> Configuring Docker log rotation"
    echo "${DESIRED_DAEMON_JSON}" | sudo tee "${DAEMON_JSON}" >/dev/null
    sudo systemctl restart docker
else
    echo "==> Docker log rotation already configured"
fi

# ---------- Swap (2 GiB swap file) ----------
# Mac SSD usage stays at ~0 until swap is actually used (Lima VM disk is sparse).
SWAPFILE=/swapfile
if ! swapon --show=NAME --noheadings | grep -qx "${SWAPFILE}"; then
    echo "==> Creating 2 GiB swap file at ${SWAPFILE}"
    if [ ! -f "${SWAPFILE}" ]; then
        sudo fallocate -l 2G "${SWAPFILE}"
        sudo chmod 600 "${SWAPFILE}"
        sudo mkswap "${SWAPFILE}"
    fi
    sudo swapon "${SWAPFILE}"
    if ! grep -q "^${SWAPFILE} " /etc/fstab; then
        echo "${SWAPFILE} none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
    fi
else
    echo "==> Swap already active on ${SWAPFILE}"
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
