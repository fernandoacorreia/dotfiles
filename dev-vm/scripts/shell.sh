#!/bin/bash
# Open an interactive shell in the VM via limactl (works even if SSH config
# isn't installed yet).
set -euo pipefail
exec limactl shell dev-vm "$@"
