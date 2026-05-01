#!/bin/bash
# Sanity-check the setup. Prints PASS/FAIL for each step.
set -uo pipefail

VM_NAME="dev-vm"
fail=0

check() {
    local label="$1"
    shift
    if "$@" >/dev/null 2>&1; then
        printf "  PASS  %s\n" "${label}"
    else
        printf "  FAIL  %s\n" "${label}"
        fail=1
    fi
}

echo "Checking prerequisites..."
check "limactl installed" command -v limactl

echo
echo "Checking VM..."
check "VM '${VM_NAME}' exists" bash -c "limactl list --quiet | grep -qx '${VM_NAME}'"
check "VM '${VM_NAME}' running" bash -c "[ \"\$(limactl list --format='{{.Status}}' '${VM_NAME}' 2>/dev/null)\" = 'Running' ]"

echo
echo "Checking SSH..."
check "ssh lima-${VM_NAME} works" ssh -o BatchMode=yes -o ConnectTimeout=5 "lima-${VM_NAME}" true
check "limactl shell works" limactl shell "${VM_NAME}" true

echo
echo "Checking port forwarding (3000, 8088)..."
# Start a temp listener inside the VM, hit it from the host, then kill it.
test_port() {
    local port="$1"
    limactl shell "${VM_NAME}" bash -c "
        (nohup python3 -m http.server ${port} --bind 127.0.0.1 >/dev/null 2>&1 &)
        for _ in 1 2 3 4 5; do
            ss -ltn 'sport = :${port}' | grep -q LISTEN && break
            sleep 0.5
        done
    " >/dev/null 2>&1
    sleep 1
    local ok=1
    curl -sf -o /dev/null --max-time 3 "http://localhost:${port}/" && ok=0
    limactl shell "${VM_NAME}" bash -c "pkill -f 'http.server ${port}' || true" >/dev/null 2>&1
    return ${ok}
}

if [ "$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null)" = "Running" ]; then
    check "port 3000 reachable as localhost:3000" test_port 3000
    check "port 8088 reachable as localhost:8088" test_port 8088
else
    echo "  SKIP  port forwarding (VM not running)"
fi

echo
echo "Checking host-path sharing (only ~/dev-vm-shared should be mounted)..."

# Check A: resolved per-instance Lima config.
# Catches inherited mounts (e.g. ~ via template:_default/mounts) that bypass
# scripts/create.sh's scrub or were added later via `limactl edit`.
LIMA_YAML="${HOME}/.lima/${VM_NAME}/lima.yaml"
if ! command -v yq >/dev/null 2>&1; then
    printf "  FAIL  yq missing (run scripts/install-prereqs.sh)\n"
    fail=1
elif [ ! -f "${LIMA_YAML}" ]; then
    printf "  FAIL  resolved Lima config not found: %s\n" "${LIMA_YAML}"
    fail=1
else
    extras="$(yq -r '.mounts[] | select(.location != "~/dev-vm-shared") | .location' "${LIMA_YAML}")"
    if [ -z "${extras}" ]; then
        printf "  PASS  only ~/dev-vm-shared in resolved lima.yaml\n"
    else
        printf "  FAIL  extra mounts in %s:\n" "${LIMA_YAML}"
        while IFS= read -r loc; do printf "          %s\n" "${loc}"; done <<<"${extras}"
        fail=1
    fi
fi

# Check B: live virtiofs mount table inside the VM.
# Catches any drift between the resolved config and what the kernel actually
# mounted at boot.
if [ "$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null)" = "Running" ]; then
    guest_user="$(limactl shell "${VM_NAME}" -- whoami 2>/dev/null | tr -d '\r')"
    expected="/home/${guest_user}/dev-vm-shared"
    targets="$(limactl shell "${VM_NAME}" -- findmnt -t virtiofs -n -o TARGET 2>/dev/null | tr -d '\r')"
    extras="$(printf "%s\n" "${targets}" | grep -v -x "${expected}" | grep -v '^$' || true)"
    if [ -z "${extras}" ] && [ -n "${targets}" ]; then
        printf "  PASS  only %s mounted inside VM (virtiofs)\n" "${expected}"
    elif [ -z "${targets}" ]; then
        printf "  FAIL  no virtiofs mounts inside VM (expected %s)\n" "${expected}"
        fail=1
    else
        printf "  FAIL  extra virtiofs mounts inside VM:\n"
        while IFS= read -r t; do printf "          %s\n" "${t}"; done <<<"${extras}"
        fail=1
    fi
else
    echo "  SKIP  live virtiofs mount check (VM not running)"
fi

echo
echo "Checking iTerm2 shell integration inside VM..."
# iTerm2's integration script sets ITERM_SHELL_INTEGRATION_INSTALLED=Yes when
# sourced. Run an interactive zsh so ~/.zshrc gets sourced, and verify the
# variable is set. The ansible `shell` role downloads the integration script
# and ~/.zshrc sources it when present.
test_iterm_integration() {
    local val
    # Force TERM=xterm-256color: limactl shell runs without a tty, so TERM
    # would otherwise be 'dumb' and the iTerm2 script self-skips. Strip the
    # OSC 1337 escape sequences the script emits when it loads.
    val="$(limactl shell "${VM_NAME}" -- bash -c 'TERM=xterm-256color zsh -ic '"'"'printf %s "${ITERM_SHELL_INTEGRATION_INSTALLED:-}"'"'"'' 2>/dev/null | tr -d '\r' | sed $'s/\x1b\\][^\x07]*\x07//g')"
    [ "${val##*$'\x07'}" = "Yes" ] || [ "${val}" = "Yes" ]
}
if [ "$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null)" = "Running" ]; then
    check "ITERM_SHELL_INTEGRATION_INSTALLED set in interactive shell" test_iterm_integration
else
    echo "  SKIP  iTerm2 shell integration (VM not running)"
fi

echo
if [ "${fail}" -eq 0 ]; then
    echo "All checks passed."
else
    echo "Some checks failed."
    exit 1
fi
