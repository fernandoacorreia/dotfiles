#!/bin/bash
# Add (or refresh) a `Host dev-vm` block in ~/.ssh/config so `ssh dev-vm`
# connects to the Lima VM. Re-running replaces the managed block.
set -euo pipefail

VM_NAME="dev-vm"
SSH_CONFIG="${HOME}/.ssh/config"
BEGIN="# >>> vms (lima) >>>"
END="# <<< vms (lima) <<<"

if ! limactl list --quiet | grep -qx "${VM_NAME}"; then
    echo "VM '${VM_NAME}' does not exist. Run scripts/create.sh first." >&2
    exit 1
fi

# Pull the auto-generated SSH config from Lima and rewrite the Host line.
lima_ssh_config="${HOME}/.lima/${VM_NAME}/ssh.config"
if [ ! -f "${lima_ssh_config}" ]; then
    echo "Lima SSH config not found at ${lima_ssh_config}." >&2
    echo "Make sure the VM is started: ./scripts/start.sh" >&2
    exit 1
fi
lima_config="$(cat "${lima_ssh_config}")"

# Replace `Host lima-${VM_NAME}` with `Host ${VM_NAME}`.
managed_block="$(printf '%s\n%s\n%s\n' \
    "${BEGIN}" \
    "$(printf '%s' "${lima_config}" | sed "s/^Host lima-${VM_NAME}\$/Host ${VM_NAME}/")" \
    "${END}")"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
touch "${SSH_CONFIG}"
chmod 600 "${SSH_CONFIG}"

# Strip any previous managed block, then append the fresh one.
tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT
awk -v b="${BEGIN}" -v e="${END}" '
    $0==b {skip=1; next}
    $0==e {skip=0; next}
    !skip {print}
' "${SSH_CONFIG}" > "${tmp}"

# Ensure trailing newline before appending.
if [ -s "${tmp}" ] && [ "$(tail -c1 "${tmp}" | wc -l)" -eq 0 ]; then
    printf '\n' >> "${tmp}"
fi
printf '%s\n' "${managed_block}" >> "${tmp}"

mv "${tmp}" "${SSH_CONFIG}"
chmod 600 "${SSH_CONFIG}"
trap - EXIT

echo "==> Wrote managed 'Host ${VM_NAME}' block to ${SSH_CONFIG}"
echo "    Try it:  ssh ${VM_NAME}"
