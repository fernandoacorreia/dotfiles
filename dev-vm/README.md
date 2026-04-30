# Ubuntu ARM64 VM on macOS (Lima)

A turnkey, terminal-only Ubuntu Server VM for Apple Silicon Macs (macOS 26 Tahoe), built on [Lima](https://lima-vm.io). Native ARM64 virtualization (Apple Virtualization framework, no emulation), accessible by `ssh dev-vm`, with ports `3000` and `8088` auto-forwarded to `localhost` on the Mac.

## Prerequisites

- macOS on Apple Silicon (M-series).
- [Homebrew](https://brew.sh) installed.

SSH access is provided automatically: Lima generates its own keypair (`~/.lima/_config/user{,.pub}`) on first run and authorizes the public key inside the VM. No host SSH key is required. To also authorize every `~/.ssh/*.pub` key, set `loadDotSSHPubKeys: true` in `dev-vm.yaml`.

## Quick start

```bash
./scripts/install-prereqs.sh        # brew install lima
./scripts/create.sh                 # ~5-10 min on first run
./scripts/ssh-config-install.sh     # adds `Host dev-vm` to ~/.ssh/config
ssh dev-vm                          # done
```

Inside the VM, ports `3000` and `8088` are reachable from the Mac as `http://localhost:3000` and `http://localhost:8088`. See [Port forwarding](#port-forwarding) below if you need additional ports.

## Customizing the dev environment

The user-customizable provisioning script is `scripts/dev-setup.sh`. It runs once during `create.sh` and any time you call `reprovision.sh`. The initial stub installs Docker only — extend it with whatever you need.

```bash
$EDITOR scripts/dev-setup.sh
./scripts/reprovision.sh            # re-run inside the existing VM
```

`dev-setup.sh` should be idempotent (safe to re-run). The Docker block in the stub is already idempotent — follow the same pattern for additions.

### Per-machine hook (outside the repo)

At the end of `dev-setup.sh`, if `~/dev-vm-shared/dev-vm-setup.sh` exists on the Mac it is run **inside the VM** (the host `~/dev-vm-shared` is mounted at the guest's `~/dev-vm-shared` — i.e. `/home/$USER/dev-vm-shared` — so home-relative paths resolve to the same content on the host and inside the VM). Use this for machine-specific or private setup you don't want to commit — credentials, work-only tools, personal dotfiles, anything that shouldn't live in this repo.

```bash
$EDITOR ~/dev-vm-shared/dev-vm-setup.sh   # any bash script
chmod +x ~/dev-vm-shared/dev-vm-setup.sh  # not strictly required; we invoke via `bash`
./scripts/reprovision.sh             # apply
```

## Port forwarding

Lima 2.x auto-forwards guest ports bound on `127.0.0.1` only. Ports bound on `0.0.0.0` require an explicit `portForwards:` entry in `dev-vm.yaml`. We declare 3000 and 8088 there, so they're reachable from the Mac as `http://localhost:3000` / `http://localhost:8088` regardless of bind address.

To forward additional ports, add entries to the `portForwards:` list (and restart the VM). To forward a range, use `guestPortRange`:

```yaml
portForwards:
  - guestPortRange: [9000, 9099]
    hostIP: "127.0.0.1"
```

## Common commands

| Command | What it does |
|---|---|
| `./scripts/start.sh` | Start the VM |
| `./scripts/stop.sh` | Stop the VM |
| `./scripts/status.sh` | Show VM status and configured ports |
| `./scripts/shell.sh` | Interactive shell via `limactl` (works without SSH config) |
| `./scripts/ssh.sh` | `ssh dev-vm` |
| `./scripts/reprovision.sh` | Re-run `scripts/dev-setup.sh` inside the VM |
| `./scripts/doctor.sh` | Sanity checks: VM running, SSH works, ports forwarded |
| `./scripts/delete.sh` | Permanently delete the VM (typed confirmation) |

## Customizing VM size

Edit `cpus`, `memory`, or `disk` in `dev-vm.yaml`, then:

```bash
./scripts/stop.sh
./scripts/start.sh
```

CPU and memory changes take effect on next start. **Disk resize requires recreating the VM** (`./scripts/delete.sh && ./scripts/create.sh`) — back up first if you have data inside.

## Switching Ubuntu versions

`dev-vm.yaml` pins Ubuntu 24.04 LTS. To use 26.04 LTS, change the `images:` URL to:

```
https://cloud-images.ubuntu.com/releases/26.04/release/ubuntu-26.04-server-cloudimg-arm64.img
```

You'll need to recreate the VM to apply (`delete.sh && create.sh`).

## What's shared with the VM

Important if you're running AI agents inside. Audit before trusting the VM with anything sensitive on your Mac.

**Shared / reachable from inside the VM:**

| Surface | What it is | How to tighten |
|---|---|---|
| `~/dev-vm-shared/` | Single directory mounted into the VM at the guest user's `~/dev-vm-shared` (so home-relative paths match on host and guest). Distinct from `~/.lima/dev-vm/`, which is Lima's internal storage for the VM. | Don't put secrets in there. |
| Lima's auto-generated SSH pubkey (`~/.lima/_config/user.pub`) | Authorizes inbound SSH from your Mac into the VM. The matching private key lives on your Mac only. | n/a — required for `ssh dev-vm` to work. |
| Outbound internet | Full, unrestricted via NAT. | Add `iptables`/`nftables` rules in `scripts/dev-setup.sh` to allowlist domains/IPs. |
| **Mac reachable as `host.lima.internal`** | The VM can connect *back* to any service running on your Mac (localhost-bound dev servers, databases, MCP servers, Ollama, etc.). | See "Blocking host access" below. |
| User account | Lima creates a Linux user matching your Mac username with passwordless `sudo`. Compromise inside the VM = root inside the VM (does not escape). | Tighten via `/etc/sudoers.d/` in `dev-setup.sh` if needed. |

**Not shared (the VM cannot see):**

- Anything in `~/` outside `~/dev-vm-shared/` — `~/.ssh` private keys, `~/.aws`, `~/.config/gcloud`, `~/.netrc`, git credentials, browser data.
- macOS Keychain, Apple Passwords, 1Password.
- Mac environment variables, processes, open ports (other than via `host.lima.internal` if a service is listening).
- Clipboard, microphone, camera, screen.
- macOS DNS resolver state, time zone settings (the VM has its own).

### Blocking host access

By default, AI agents inside the VM can reach `host.lima.internal` and your Mac's LAN gateway. If that's a concern, add to `scripts/dev-setup.sh`:

```bash
# Block VM -> Mac host reachability (drops anything destined for the host
# or the Mac's LAN). Outbound to the public internet still works.
HOST_IP="$(getent hosts host.lima.internal | awk '{print $1}')"
if [ -n "${HOST_IP}" ]; then
    sudo iptables -A OUTPUT -d "${HOST_IP}" -j REJECT
    sudo iptables -A OUTPUT -d 192.168.0.0/16 -j REJECT
    sudo iptables -A OUTPUT -d 10.0.0.0/8 -j REJECT
    sudo iptables -A OUTPUT -d 172.16.0.0/12 -j REJECT
fi
```

Then `./scripts/reprovision.sh`. Note this also blocks Lima's automatic port forwarding for the VM-to-host direction; host-to-VM forwarding (3000/8088) is unaffected.

### File sharing details

`scripts/install-prereqs.sh` creates `~/dev-vm-shared/` on the Mac and `scripts/create.sh` mounts it into the VM at the guest's `~/dev-vm-shared`. To share something, drop it in there. The mount is read-write from both sides.

For best build performance, work inside the VM's own filesystem (e.g. `~/work` on the VM disk) rather than on the mounted Mac path.

## Other useful `limactl` commands

The wrapper scripts cover the common cases. For everything else, `limactl` is what they call under the hood — these are worth knowing:

| Command | What it does |
|---|---|
| `limactl list` | All VMs and their state (add `--json` for scripting). |
| `limactl shell dev-vm -- <cmd>` | Run a one-off command inside the VM without an interactive shell. |
| `limactl copy <src> <dst>` | `scp`-style copy, e.g. `limactl copy ./file dev-vm:/tmp/`. |
| `limactl show-ssh dev-vm` | Print the SSH config block Lima would use — useful when debugging `ssh-config-install.sh`. |
| `limactl edit dev-vm` | Edit the live VM's `lima.yaml`. Apply with `stop` + `start`. |
| `limactl restart dev-vm` | Stop + start in one step. |
| `limactl tunnel dev-vm --tcp <host:port>` | Ad-hoc port forward without editing `dev-vm.yaml`. |
| `limactl factory-reset dev-vm` | Wipe disk state but keep the VM definition (lighter than delete + create). |
| `limactl snapshot create\|list\|apply\|delete dev-vm --name <n>` | VM snapshots (supported on the `vz` driver this VM uses). |
| `limactl protect dev-vm` / `unprotect` | Guard against accidental `limactl delete`. |
| `limactl disk list\|create\|delete` | Manage external persistent disks you can attach in `dev-vm.yaml`. |
| `limactl info` | Lima version, default template paths, supported drivers. |
| `limactl completion zsh` | Shell completions. |

## Troubleshooting

**`limactl: command not found`**: run `./scripts/install-prereqs.sh`, then open a fresh shell.

**`create.sh` hangs on first boot**: cloud image download (~600 MB) and cloud-init can take 5-10 minutes the first time. Watch progress in another terminal with `limactl shell dev-vm -- sudo journalctl -fu cloud-final` or `tail -f ~/.lima/dev-vm/serial*.log`.

**Port 3000/8088 not reachable from Mac**: verify the VM is running (`./scripts/status.sh`) and that the service inside the VM is actually listening (`ssh dev-vm 'ss -ltn'`). `./scripts/doctor.sh` runs an end-to-end check.

**SSH says "Connection refused" or wrong port**: re-run `./scripts/ssh-config-install.sh`. Lima sometimes picks a new local SSH port between VM rebuilds, and that script refreshes the managed block in `~/.ssh/config`.

**VM is wedged / won't start**: `./scripts/delete.sh && ./scripts/create.sh`. The dev environment is reproducible from `dev-vm.yaml` + `dev-setup.sh`, so rebuilds are cheap.

## Uninstall

```bash
./scripts/delete.sh
brew uninstall lima
```

Also remove the `# >>> vms (lima) >>>` block from `~/.ssh/config` if you want it gone.

## Layout

```
vms/
├── README.md                  # this file
├── dev-vm.yaml                # Lima VM config (single source of truth)
└── scripts/                   # VM management scripts
```
