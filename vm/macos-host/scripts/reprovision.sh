#!/bin/bash
# Re-run scripts/dev-setup.sh inside a running VM. Use this after editing
# dev-setup.sh (or your ~/dev-vm-shared/dev-vm-setup.sh hook) to apply changes
# without rebuilding the VM.
set -euo pipefail
cd "$(dirname "$0")/.."

VM_NAME="dev-vm"

status="$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null || true)"
if [ "${status}" != "Running" ]; then
    echo "VM '${VM_NAME}' is not running (status: ${status:-missing})." >&2
    echo "Start it with: ./scripts/start.sh" >&2
    exit 1
fi

echo "==> Running scripts/dev-setup.sh inside VM"
limactl shell --workdir=/tmp "${VM_NAME}" bash < ./scripts/dev-setup.sh
echo "==> Done."
