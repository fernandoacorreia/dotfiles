#!/bin/bash
# Install Lima via Homebrew. Safe to re-run.
set -euo pipefail

if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required. Install from https://brew.sh and re-run." >&2
    exit 1
fi

if command -v limactl >/dev/null 2>&1; then
    echo "limactl already installed: $(limactl --version | head -1)"
else
    echo "==> Installing lima"
    brew install lima
    echo "==> $(limactl --version | head -1)"
fi

# yq is used by create.sh and doctor.sh to scrub/validate the resolved Lima
# config. See dev-vm.yaml for why we need to scrub mounts.
if command -v yq >/dev/null 2>&1; then
    echo "yq already installed: $(yq --version)"
else
    echo "==> Installing yq"
    brew install yq
fi

# Host-side mount target for the VM (see dev-vm.yaml `mounts:`).
mkdir -p "${HOME}/dev-vm-shared"

if [ -d "${HOME}/dev-vm" ] && [ ! -L "${HOME}/dev-vm" ]; then
    echo "Note: ${HOME}/dev-vm exists. The shared dir was renamed to ${HOME}/dev-vm-shared." >&2
    echo "      If it has content you want to keep, run:" >&2
    echo "          mv ${HOME}/dev-vm/* ${HOME}/dev-vm-shared/ 2>/dev/null && rmdir ${HOME}/dev-vm" >&2
fi
