#!/bin/bash
# SSH into the VM using the alias set up by ssh-config-install.sh.
set -euo pipefail
exec ssh dev-vm "$@"
