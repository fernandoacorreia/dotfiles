#!/bin/bash
# SSH into the VM using the Include block set up by ssh-config-install.sh.
set -euo pipefail
exec ssh lima-dev-vm "$@"
