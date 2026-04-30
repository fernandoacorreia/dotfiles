#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
limactl start dev-vm
./scripts/ssh-config-install.sh
