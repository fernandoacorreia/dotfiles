#!/bin/bash
# Permanently delete the 'dev-vm' VM and all its data. Requires typed confirmation.
set -euo pipefail

VM_NAME="dev-vm"

cat <<EOF
This will permanently delete VM '${VM_NAME}' and its disk.
All data inside the VM will be lost.
EOF

printf "Type the VM name to confirm: "
read -r reply
if [ "${reply}" != "${VM_NAME}" ]; then
    echo "Aborted."
    exit 1
fi

limactl stop "${VM_NAME}" 2>/dev/null || true
limactl delete --force "${VM_NAME}"
echo "==> VM '${VM_NAME}' deleted."
