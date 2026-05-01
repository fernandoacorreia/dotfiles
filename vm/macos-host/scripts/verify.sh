#!/bin/bash
# End-to-end verification for dev-vm. Runs Phases 0-5 from the verification
# plan. Phase 6 (destroy + recreate) is intentionally NOT covered here -- run
# delete.sh + create.sh manually if you want to verify reproducibility from
# scratch.
#
# Flags:
#   --lifecycle   Run Phase 5 (stop/start cycle, slow).
#   --no-create   Fail Phase 1 instead of running create.sh if the VM is missing.
set -uo pipefail
cd "$(dirname "$0")/.."

VM_NAME="dev-vm"
LIFECYCLE=0
NO_CREATE=0
for arg in "$@"; do
    case "${arg}" in
        --lifecycle) LIFECYCLE=1 ;;
        --no-create) NO_CREATE=1 ;;
        *) echo "Unknown flag: ${arg}" >&2; exit 2 ;;
    esac
done

fail=0
pass_count=0
fail_count=0
skip_count=0

check() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        printf "  PASS  %s\n" "${label}"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  %s\n" "${label}"
        fail=1
        fail_count=$((fail_count + 1))
    fi
}

skip() {
    printf "  SKIP  %s\n" "$1"
    skip_count=$((skip_count + 1))
}

phase() {
    printf "\n==> %s\n" "$1"
}

vm_running() {
    [ "$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null)" = "Running" ]
}

vm_exists() {
    limactl list --quiet 2>/dev/null | grep -qx "${VM_NAME}"
}

# ============================================================
# Phase 0 -- static checks
# ============================================================
phase "Phase 0: static checks"

for f in scripts/*.sh; do
    check "bash -n ${f}" bash -n "${f}"
    check "executable ${f}" test -x "${f}"
done

if command -v limactl >/dev/null 2>&1; then
    check "limactl validate dev-vm.yaml" limactl validate dev-vm.yaml
fi

# Doc/config consistency: ports
check "README mentions port 3000" grep -qE '\b3000\b' README.md
check "README mentions port 8088" grep -qE '\b8088\b' README.md
check "dev-vm.yaml has guestPort 3000" grep -q 'guestPort: 3000' dev-vm.yaml
check "dev-vm.yaml has guestPort 8088" grep -q 'guestPort: 8088' dev-vm.yaml
check "status.sh references 3000" grep -q '3000' scripts/status.sh
check "status.sh references 8088" grep -q '8088' scripts/status.sh
check "doctor.sh references 3000" grep -q 'test_port 3000' scripts/doctor.sh
check "doctor.sh references 8088" grep -q 'test_port 8088' scripts/doctor.sh

# Doc/config consistency: Ubuntu version
check "yaml pins Ubuntu 24.04 image" grep -q 'releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img' dev-vm.yaml
check "README claims Ubuntu 24.04" grep -q '24.04' README.md

# Doc/config consistency: VM name everywhere
check "yaml filename is dev-vm.yaml" test -f dev-vm.yaml
for s in scripts/create.sh scripts/delete.sh scripts/doctor.sh scripts/reprovision.sh scripts/ssh-config-install.sh scripts/status.sh; do
    check "VM_NAME=dev-vm in ${s}" grep -qE 'VM_NAME="dev-vm"' "${s}"
done

# Doc/config: SSH key loading policy
check "yaml has loadDotSSHPubKeys: false" grep -qE 'loadDotSSHPubKeys:\s*false' dev-vm.yaml
if grep -qE 'authorizes all \`~/\.ssh/\*\.pub\` keys' README.md || \
   grep -qE 'authorizes all ~/\.ssh/\*\.pub keys' README.md; then
    printf "  FAIL  README claims all ~/.ssh/*.pub keys are authorized (yaml says loadDotSSHPubKeys: false)\n"
    fail=1; fail_count=$((fail_count + 1))
else
    printf "  PASS  README does not falsely claim ~/.ssh/*.pub keys are authorized\n"
    pass_count=$((pass_count + 1))
fi

# Doc/config: writable mount default
check "yaml mount is writable: true" grep -qE 'writable:\s*true' dev-vm.yaml
if grep -q 'Read-only by default' README.md; then
    printf "  FAIL  README mount-default narrative matches yaml (writable)\n"
    fail=1; fail_count=$((fail_count + 1))
else
    printf "  PASS  README mount-default narrative matches yaml (writable)\n"
    pass_count=$((pass_count + 1))
fi

# Doc/config: mountPoint path symmetry
check "yaml has mountPoint anchored to guest \$HOME" grep -qE 'mountPoint:\s*"\{\{\.Home\}\}/dev-vm-shared"' dev-vm.yaml
check "yaml has user.home override" grep -qE '^\s*home:\s*"/home/\{\{\.User\}\}"' dev-vm.yaml
if grep -q '/Users/${USER}/dev-vm-shared/dev-vm-setup.sh' scripts/dev-setup.sh; then
    printf "  FAIL  dev-setup.sh hook path is /Users/... (will not exist in VM after mountPoint change)\n"
    fail=1; fail_count=$((fail_count + 1))
else
    printf "  PASS  dev-setup.sh hook path is not Mac-only\n"
    pass_count=$((pass_count + 1))
fi
if grep -q '/Users/\$USER/dev-vm-shared' README.md; then
    printf "  FAIL  README still references /Users/\$USER/dev-vm-shared as the in-VM path\n"
    fail=1; fail_count=$((fail_count + 1))
else
    printf "  PASS  README does not claim /Users/\$USER/dev-vm-shared is the in-VM path\n"
    pass_count=$((pass_count + 1))
fi

# ============================================================
# Phase 1 -- fresh-install happy path (idempotent: skips create if VM exists)
# ============================================================
phase "Phase 1: install + create + ssh-config"

check "install-prereqs.sh runs cleanly" bash ./scripts/install-prereqs.sh
check "~/dev-vm-shared host dir exists after prereqs" test -d "${HOME}/dev-vm-shared"
check "install-prereqs.sh is idempotent (re-run)" bash ./scripts/install-prereqs.sh

if vm_exists; then
    skip "create.sh (VM '${VM_NAME}' already exists)"
elif [ "${NO_CREATE}" -eq 1 ]; then
    printf "  FAIL  VM does not exist and --no-create was passed\n"
    fail=1; fail_count=$((fail_count + 1))
else
    echo "  ... running create.sh (this can take 5-10 min on first boot)"
    if bash ./scripts/create.sh; then
        printf "  PASS  create.sh completed\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  create.sh failed -- aborting later phases\n"
        fail=1; fail_count=$((fail_count + 1))
        exit 1
    fi
fi

check "VM exists" vm_exists
check "VM is running" vm_running

if vm_running; then
    check "ssh-config-install.sh succeeds" bash ./scripts/ssh-config-install.sh
    check "managed block in ~/.ssh/config" grep -q '# >>> vms (lima) >>>' "${HOME}/.ssh/config"
    # Idempotent: re-run should still leave exactly one block.
    bash ./scripts/ssh-config-install.sh >/dev/null 2>&1
    block_count=$(grep -c '# >>> vms (lima) >>>' "${HOME}/.ssh/config" 2>/dev/null || echo 0)
    if [ "${block_count}" = "1" ]; then
        printf "  PASS  ssh-config-install.sh idempotent (single managed block)\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  ssh-config-install.sh idempotent (found %s blocks)\n" "${block_count}"
        fail=1; fail_count=$((fail_count + 1))
    fi
    check "ssh dev-vm true" ssh -o BatchMode=yes -o ConnectTimeout=5 dev-vm true
else
    skip "ssh-config + ssh checks (VM not running)"
fi

# ============================================================
# Phase 2 -- doctor.sh
# ============================================================
phase "Phase 2: doctor.sh end-to-end"
if vm_running; then
    if bash ./scripts/doctor.sh >/tmp/dev-vm-doctor.log 2>&1; then
        printf "  PASS  doctor.sh all checks passed\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  doctor.sh reported failures (see /tmp/dev-vm-doctor.log)\n"
        fail=1; fail_count=$((fail_count + 1))
    fi
    sed 's/^/    /' /tmp/dev-vm-doctor.log
else
    skip "doctor.sh (VM not running)"
fi

# ============================================================
# Phase 3 -- behavioral checks
# ============================================================
phase "Phase 3: behavioral checks"

PROBE_MAC="${HOME}/dev-vm-shared/probe-mac.txt"
PROBE_VM="${HOME}/dev-vm-shared/probe-vm.txt"
PROBE_SYM="${HOME}/dev-vm-shared/probe-symmetry.txt"
HOOK_FILE="${HOME}/dev-vm-shared/dev-vm-setup.sh"
HOST_HTTP_PID=""

cleanup() {
    rm -f "${PROBE_MAC}" "${PROBE_VM}" "${PROBE_SYM}" "${HOOK_FILE}" 2>/dev/null || true
    if vm_running; then
        ssh -o BatchMode=yes dev-vm 'rm -f /tmp/dev-vm-hook-marker; pkill -f "http.server 9991" 2>/dev/null || true' >/dev/null 2>&1 || true
    fi
    if [ -n "${HOST_HTTP_PID}" ]; then
        kill "${HOST_HTTP_PID}" 2>/dev/null || true
    fi
}
trap cleanup EXIT

if vm_running; then
    # 5. Mount sharing, writability, path symmetry
    echo from-mac > "${PROBE_MAC}"
    if [ "$(ssh -o BatchMode=yes dev-vm 'cat ~/dev-vm-shared/probe-mac.txt' 2>/dev/null)" = "from-mac" ]; then
        printf "  PASS  Mac->VM mount visibility (~/dev-vm-shared same path)\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  Mac->VM mount visibility (~/dev-vm-shared same path)\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    if ssh -o BatchMode=yes dev-vm 'echo from-vm > ~/dev-vm-shared/probe-vm.txt' 2>/dev/null; then
        printf "  PASS  VM can write into ~/dev-vm-shared (writable mount)\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  VM can write into ~/dev-vm-shared (writable mount)\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    if [ "$(cat "${PROBE_VM}" 2>/dev/null)" = "from-vm" ]; then
        printf "  PASS  VM->Mac round-trip visible at same host path\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  VM->Mac round-trip visible at same host path\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    vm_resolved="$(ssh -o BatchMode=yes dev-vm 'readlink -f ~/dev-vm-shared' 2>/dev/null || true)"
    if [ "${vm_resolved}" = "/home/${USER}/dev-vm-shared" ]; then
        printf "  PASS  VM ~/dev-vm-shared resolves to /home/%s/dev-vm-shared\n" "${USER}"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  VM ~/dev-vm-shared resolves to '%s' (expected /home/%s/dev-vm-shared)\n" "${vm_resolved}" "${USER}"
        fail=1; fail_count=$((fail_count + 1))
    fi

    mac_resolved="$(cd "${HOME}/dev-vm-shared" && pwd -P)"
    expected_mac="/Users/${USER}/dev-vm-shared"
    if [ "${mac_resolved}" = "${expected_mac}" ]; then
        printf "  PASS  Mac ~/dev-vm-shared resolves to /Users/%s/dev-vm-shared\n" "${USER}"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  Mac ~/dev-vm-shared resolves to '%s' (expected %s)\n" "${mac_resolved}" "${expected_mac}"
        fail=1; fail_count=$((fail_count + 1))
    fi

    echo same-relative > "${PROBE_SYM}"
    sym_vm="$(ssh -o BatchMode=yes dev-vm 'cat ~/dev-vm-shared/probe-symmetry.txt' 2>/dev/null)"
    if [ "${sym_vm}" = "same-relative" ]; then
        printf "  PASS  ~/dev-vm-shared/<file> reachable from both sides via identical path\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  ~/dev-vm-shared/<file> reachable from both sides via identical path\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 6. Lima 2.x port-forwarding policy: declared ports work; an undeclared
    # port bound on 0.0.0.0 should NOT be reachable from the host.
    ssh -o BatchMode=yes dev-vm 'pkill -f "http.server 9991" 2>/dev/null; (nohup python3 -m http.server 9991 --bind 0.0.0.0 >/dev/null 2>&1 &)' >/dev/null 2>&1
    for _ in 1 2 3 4 5 6 7 8; do
        ssh -o BatchMode=yes dev-vm "ss -ltn 'sport = :9991'" 2>/dev/null | grep -q LISTEN && break
        sleep 0.5
    done
    sleep 2
    if curl -sf -o /dev/null --max-time 3 http://localhost:9991/; then
        printf "  FAIL  Lima 2.x should NOT auto-forward 0.0.0.0 binds (9991 was reachable)\n"
        fail=1; fail_count=$((fail_count + 1))
    else
        printf "  PASS  Lima 2.x policy: undeclared 0.0.0.0 port is not auto-forwarded\n"
        pass_count=$((pass_count + 1))
    fi
    ssh -o BatchMode=yes dev-vm 'pkill -f "http.server 9991" 2>/dev/null || true' >/dev/null 2>&1

    # 7. host.lima.internal reachable
    check "host.lima.internal resolves in VM" \
        ssh -o BatchMode=yes dev-vm 'getent hosts host.lima.internal'
    # Spin up a host listener and probe it from VM. python's http.server logs
    # "Serving HTTP on 127.0.0.1 port NNNN" -- match that exact form. -u keeps
    # stdout/stderr unbuffered so the line shows up before we grep it.
    python3 -u -m http.server 0 --bind 127.0.0.1 >/tmp/dev-vm-hostsrv.log 2>&1 &
    HOST_HTTP_PID=$!
    sleep 1
    host_port="$(grep -oE 'port [0-9]+' /tmp/dev-vm-hostsrv.log | head -1 | awk '{print $2}')"
    if [ -z "${host_port}" ]; then
        # newer python: "Serving HTTP on 0.0.0.0 port 12345"
        host_port="$(grep -oE '[Pp]ort [0-9]+' /tmp/dev-vm-hostsrv.log | head -1 | awk '{print $2}')"
    fi
    if [ -n "${host_port}" ]; then
        if ssh -o BatchMode=yes dev-vm "curl -sf -o /dev/null --max-time 5 http://host.lima.internal:${host_port}/"; then
            printf "  PASS  VM can reach Mac via host.lima.internal:%s\n" "${host_port}"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  VM can reach Mac via host.lima.internal:%s\n" "${host_port}"
            fail=1; fail_count=$((fail_count + 1))
        fi
    else
        printf "  FAIL  could not start host probe http server\n"
        fail=1; fail_count=$((fail_count + 1))
    fi
    kill "${HOST_HTTP_PID}" 2>/dev/null || true
    HOST_HTTP_PID=""

    # 8. Base packages (gnupg's binary is `gpg`)
    if missing="$(ssh -o BatchMode=yes dev-vm 'for p in git vim htop tmux jq unzip rsync curl gpg; do command -v "$p" >/dev/null || echo "$p"; done')" \
        && [ -z "${missing}" ]; then
        printf "  PASS  base packages installed (git, vim, htop, tmux, jq, unzip, rsync, curl, gpg)\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  missing base packages: %s\n" "${missing:-<ssh failed>}"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 9. qemu-guest-agent should NOT be installed (vmType: vz uses Apple
    # Virtualization Framework, not QEMU).
    if ssh -o BatchMode=yes dev-vm 'dpkg -s qemu-guest-agent' >/dev/null 2>&1; then
        printf "  FAIL  qemu-guest-agent unexpectedly installed (irrelevant for vmType: vz)\n"
        fail=1; fail_count=$((fail_count + 1))
    else
        printf "  PASS  qemu-guest-agent not installed (irrelevant for vmType: vz)\n"
        pass_count=$((pass_count + 1))
    fi

    # 10. Docker hello-world (requires arm64 image pull; can be slow first time)
    echo "  ... pulling and running hello-world (first run can take ~30s)"
    if ssh -o BatchMode=yes dev-vm 'docker run --rm hello-world' >/tmp/dev-vm-docker-hw.log 2>&1; then
        printf "  PASS  docker run --rm hello-world\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  docker run --rm hello-world (see /tmp/dev-vm-docker-hw.log)\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 11. Docker is running in rootless mode (template:docker default —
    # daemon runs as the user, so no docker group membership is needed).
    check "Docker daemon is rootless" \
        ssh -o BatchMode=yes dev-vm 'docker info 2>/dev/null | grep -qi "rootless"'

    # 12. Ubuntu version
    if [ "$(ssh -o BatchMode=yes dev-vm 'lsb_release -rs' 2>/dev/null)" = "24.04" ]; then
        printf "  PASS  VM is Ubuntu 24.04\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  VM is not Ubuntu 24.04\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 13. VM specs (cpus / memory / disk)
    cpus="$(limactl list --format='{{.CPUs}}' "${VM_NAME}" 2>/dev/null)"
    mem="$(limactl list --format='{{.Memory}}' "${VM_NAME}" 2>/dev/null)"
    dsk="$(limactl list --format='{{.Disk}}' "${VM_NAME}" 2>/dev/null)"
    if [ "${cpus}" = "4" ]; then
        printf "  PASS  cpus=4\n"; pass_count=$((pass_count + 1))
    else
        printf "  FAIL  cpus=%s (expected 4)\n" "${cpus}"; fail=1; fail_count=$((fail_count + 1))
    fi
    # Lima may report memory/disk in bytes; accept either '16GiB' or matching byte counts.
    if [ "${mem}" = "16GiB" ] || [ "${mem}" = "17179869184" ]; then
        printf "  PASS  memory=16GiB\n"; pass_count=$((pass_count + 1))
    else
        printf "  FAIL  memory=%s (expected 16GiB)\n" "${mem}"; fail=1; fail_count=$((fail_count + 1))
    fi
    if [ "${dsk}" = "80GiB" ] || [ "${dsk}" = "85899345920" ]; then
        printf "  PASS  disk=80GiB\n"; pass_count=$((pass_count + 1))
    else
        printf "  FAIL  disk=%s (expected 80GiB)\n" "${dsk}"; fail=1; fail_count=$((fail_count + 1))
    fi

    # 14. uname -m
    if [ "$(ssh -o BatchMode=yes dev-vm 'uname -m' 2>/dev/null)" = "aarch64" ]; then
        printf "  PASS  uname -m = aarch64\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  uname -m != aarch64\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 15. loadDotSSHPubKeys: false honored. Lima's auto-generated pubkey lives at
    # ~/.lima/_config/user.pub on the host; the VM's authorized_keys should contain
    # exactly that one key.
    expected_key="$(awk '{print $2}' "${HOME}/.lima/_config/user.pub" 2>/dev/null)"
    in_vm="$(ssh -o BatchMode=yes dev-vm 'cat ~/.ssh/authorized_keys' 2>/dev/null)"
    line_count="$(printf '%s\n' "${in_vm}" | grep -cE '^[A-Za-z0-9-]+ ' || echo 0)"
    if [ -n "${expected_key}" ] && printf '%s\n' "${in_vm}" | grep -qF "${expected_key}"; then
        if [ "${line_count}" = "1" ]; then
            printf "  PASS  authorized_keys contains only Lima's auto-generated key\n"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  authorized_keys has %s key lines (expected 1)\n" "${line_count}"
            fail=1; fail_count=$((fail_count + 1))
        fi
    else
        printf "  FAIL  Lima's pubkey not present in VM authorized_keys\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # cleanup probes from §5 here so later phases are clean
    rm -f "${PROBE_MAC}" "${PROBE_VM}" "${PROBE_SYM}"
else
    skip "Phase 3 behavioral checks (VM not running)"
fi

# ============================================================
# Phase 4 -- idempotency & re-provisioning
# ============================================================
phase "Phase 4: idempotency & hooks"

if vm_running; then
    # 16. dev-setup.sh re-run is safe (idempotent). On a second run the
    # Docker log-rotation block should report "already configured" rather
    # than rewriting the file or restarting the daemon.
    if bash ./scripts/reprovision.sh >/tmp/dev-vm-reprov.log 2>&1; then
        if grep -q 'Docker log rotation already configured' /tmp/dev-vm-reprov.log; then
            printf "  PASS  reprovision.sh is idempotent (log rotation already configured)\n"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  reprovision.sh ran but did not log 'Docker log rotation already configured' (see /tmp/dev-vm-reprov.log)\n"
            fail=1; fail_count=$((fail_count + 1))
        fi
    else
        printf "  FAIL  reprovision.sh failed (see /tmp/dev-vm-reprov.log)\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 17/18 ordering: run the no-hook case FIRST so we don't have to delete a
    # file from a virtiofs mount mid-run (the guest dentry cache lingers and
    # can briefly report the file still exists). The hook file is created
    # inside the run for §17 only.
    rm -f "${HOOK_FILE}"

    # 18. No-hook path (test BEFORE creating the hook file)
    if bash ./scripts/reprovision.sh >/tmp/dev-vm-reprov-nohook.log 2>&1; then
        if grep -qE 'No user hook at .* skipping' /tmp/dev-vm-reprov-nohook.log; then
            printf "  PASS  reprovision logs 'No user hook ... skipping' when hook absent\n"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  reprovision did not log 'No user hook ... skipping' (see /tmp/dev-vm-reprov-nohook.log)\n"
            fail=1; fail_count=$((fail_count + 1))
        fi
    else
        printf "  FAIL  reprovision (no hook) failed\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # 17. Hook fires
    printf '#!/bin/bash\necho HOOK_RAN > /tmp/dev-vm-hook-marker\n' > "${HOOK_FILE}"
    chmod +x "${HOOK_FILE}"
    if bash ./scripts/reprovision.sh >/tmp/dev-vm-reprov-hook.log 2>&1; then
        if grep -qE 'Running user hook' /tmp/dev-vm-reprov-hook.log; then
            printf "  PASS  reprovision logs 'Running user hook'\n"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  reprovision did not log 'Running user hook' (see /tmp/dev-vm-reprov-hook.log)\n"
            fail=1; fail_count=$((fail_count + 1))
        fi
        marker="$(ssh -o BatchMode=yes dev-vm 'cat /tmp/dev-vm-hook-marker' 2>/dev/null || true)"
        if [ "${marker}" = "HOOK_RAN" ]; then
            printf "  PASS  hook actually executed inside VM\n"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  hook did not execute (marker='%s')\n" "${marker}"
            fail=1; fail_count=$((fail_count + 1))
        fi
    else
        printf "  FAIL  reprovision (with hook) failed\n"
        fail=1; fail_count=$((fail_count + 1))
    fi
    ssh -o BatchMode=yes dev-vm 'rm -f /tmp/dev-vm-hook-marker' >/dev/null 2>&1 || true
    rm -f "${HOOK_FILE}"
else
    skip "Phase 4 (VM not running)"
fi

# ============================================================
# Phase 5 -- lifecycle (slow, gated)
# ============================================================
phase "Phase 5: lifecycle"
if [ "${LIFECYCLE}" -eq 1 ] && vm_running; then
    bash ./scripts/stop.sh >/tmp/dev-vm-stop.log 2>&1
    if [ "$(limactl list --format='{{.Status}}' "${VM_NAME}" 2>/dev/null)" = "Stopped" ]; then
        printf "  PASS  stop.sh -> Stopped\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  stop.sh did not result in Stopped status\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    # reprovision.sh while stopped should fail with the not-running message
    if bash ./scripts/reprovision.sh >/tmp/dev-vm-reprov-stopped.log 2>&1; then
        printf "  FAIL  reprovision.sh succeeded while VM stopped (expected failure)\n"
        fail=1; fail_count=$((fail_count + 1))
    else
        if grep -q 'is not running' /tmp/dev-vm-reprov-stopped.log; then
            printf "  PASS  reprovision.sh refuses when VM not running\n"
            pass_count=$((pass_count + 1))
        else
            printf "  FAIL  reprovision.sh failed but message wrong\n"
            fail=1; fail_count=$((fail_count + 1))
        fi
    fi

    bash ./scripts/start.sh >/tmp/dev-vm-start.log 2>&1
    if vm_running; then
        printf "  PASS  start.sh -> Running\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  start.sh did not bring VM up\n"
        fail=1; fail_count=$((fail_count + 1))
    fi
    check "ssh dev-vm true after restart" ssh -o BatchMode=yes -o ConnectTimeout=10 dev-vm true

    # status.sh and shell.sh
    if bash ./scripts/status.sh >/tmp/dev-vm-status.log 2>&1 && \
        grep -q '3000' /tmp/dev-vm-status.log && grep -q '8088' /tmp/dev-vm-status.log; then
        printf "  PASS  status.sh prints VM line and 3000/8088\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  status.sh output missing expected content\n"
        fail=1; fail_count=$((fail_count + 1))
    fi

    if [ "$(bash ./scripts/shell.sh -- echo ok 2>/dev/null | tr -d '\r\n')" = "ok" ]; then
        printf "  PASS  shell.sh non-interactive\n"
        pass_count=$((pass_count + 1))
    else
        printf "  FAIL  shell.sh non-interactive\n"
        fail=1; fail_count=$((fail_count + 1))
    fi
else
    if [ "${LIFECYCLE}" -ne 1 ]; then
        skip "Phase 5 lifecycle (pass --lifecycle to enable; stops and restarts the VM)"
    else
        skip "Phase 5 (VM not running)"
    fi
fi

# ============================================================
# Summary
# ============================================================
phase "Summary"
printf "  pass=%d  fail=%d  skip=%d\n" "${pass_count}" "${fail_count}" "${skip_count}"
if [ "${fail}" -eq 0 ]; then
    echo "  All checks passed."
    exit 0
else
    echo "  Some checks failed."
    exit 1
fi
