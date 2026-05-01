#!/bin/bash
# Add `Include ~/.lima/*/ssh.config` to ~/.ssh/config so `ssh lima-<vm>`
# always uses Lima's per-instance config (which Lima rewrites with the
# current forwarded port on every VM start). Idempotent.
set -euo pipefail

SSH_CONFIG="${HOME}/.ssh/config"
BEGIN="# >>> vms (lima) >>>"
END="# <<< vms (lima) <<<"
INCLUDE_LINE="Include ~/.lima/*/ssh.config"

mkdir -p "${HOME}/.ssh"
chmod 700 "${HOME}/.ssh"
touch "${SSH_CONFIG}"
chmod 600 "${SSH_CONFIG}"

# ssh reads Include directives in order, and the first value wins for any
# given option. Put the managed block at the top so per-instance settings
# (Hostname/Port/IdentityFile) are picked up before any later overrides.
managed_block="$(printf '%s\n%s\n%s\n' "${BEGIN}" "${INCLUDE_LINE}" "${END}")"

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

# Strip any previous managed block.
awk -v b="${BEGIN}" -v e="${END}" '
    $0==b {skip=1; next}
    $0==e {skip=0; next}
    !skip {print}
' "${SSH_CONFIG}" > "${tmp}"

# Prepend the fresh block.
prepended="$(mktemp)"
{
    printf '%s\n\n' "${managed_block}"
    cat "${tmp}"
} > "${prepended}"

mv "${prepended}" "${SSH_CONFIG}"
rm -f "${tmp}"
chmod 600 "${SSH_CONFIG}"
trap - EXIT

echo "==> Wrote managed Lima Include block to ${SSH_CONFIG}"
echo "    Try it:  ssh lima-dev-vm"
