#!/bin/bash
# Show VM status and forwarded ports.
set -euo pipefail

VM_NAME="dev-vm"

if ! limactl list --quiet | grep -qx "${VM_NAME}"; then
    echo "VM '${VM_NAME}' does not exist. Run scripts/create.sh."
    exit 0
fi

limactl list "${VM_NAME}"

echo
echo "Configured port forwards (from dev-vm.yaml):"
printf "  %s -> %s\n" "guest:3000" "host:127.0.0.1:3000"
printf "  %s -> %s\n" "guest:8088" "host:127.0.0.1:8088"
echo
echo "Lima also auto-forwards any other guest port that gets bound."
echo
echo "Connect to the VM:"
echo "  ssh ${VM_NAME}                    # via ~/.ssh/config (run scripts/ssh-config-install.sh first)"
echo "  limactl shell ${VM_NAME}          # via Lima directly (no SSH config needed)"
