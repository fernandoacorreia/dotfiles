#!/bin/bash
# Create + start the VM, then run the user's dev-setup.sh inside it.
# Idempotent: re-running on an existing VM just starts it (if stopped) and
# re-runs dev-setup.sh.
set -euo pipefail
cd "$(dirname "$0")/.."

VM_NAME="dev-vm"
YAML="./dev-vm.yaml"

if ! command -v limactl >/dev/null 2>&1; then
    echo "limactl not found. Run scripts/install-prereqs.sh first." >&2
    exit 1
fi

if [ ! -d "${HOME}/dev-vm-shared" ]; then
    echo "${HOME}/dev-vm-shared missing. Run scripts/install-prereqs.sh first." >&2
    exit 1
fi

# Create if missing.
if ! limactl list --quiet | grep -qx "${VM_NAME}"; then
    echo "==> Creating VM '${VM_NAME}' from ${YAML}"
    limactl create --name="${VM_NAME}" --tty=false "${YAML}"
fi

# Start if not running.
status="$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null || true)"
if [ "${status}" != "Running" ]; then
    echo "==> Starting VM '${VM_NAME}' (this can take 5-10 min on first boot)"
    limactl start "${VM_NAME}"
else
    echo "==> VM '${VM_NAME}' already running"
fi

# Run user-customizable provisioning.
echo "==> Running scripts/dev-setup.sh inside VM"
limactl shell --workdir=/tmp "${VM_NAME}" bash < ./scripts/dev-setup.sh

# Kill the per-VM SSH ControlMaster so subsequent ssh sessions pick up
# any group/env changes made by dev-setup.sh or the user hook.
ssh -F "${HOME}/.lima/${VM_NAME}/ssh.config" -O exit "lima-${VM_NAME}" 2>/dev/null || true

cat <<'EOF'

==> VM is ready.

Next steps:
  ./scripts/ssh-config-install.sh    # add `Host dev-vm` to ~/.ssh/config
  ssh dev-vm                         # connect

Ports 3000 and 8088 inside the VM are auto-forwarded to localhost on this Mac.
EOF
