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
check "ssh ${VM_NAME} works" ssh -o BatchMode=yes -o ConnectTimeout=5 "${VM_NAME}" true
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
if [ "${fail}" -eq 0 ]; then
    echo "All checks passed."
else
    echo "Some checks failed."
    exit 1
fi
