#!/bin/bash
#
# Shared helpers for dev scripts. Source this, don't execute it.
#

IMAGE_NAME="dotfiles-dev"
PLATFORM=""

# Parse --platform from any position in the argument list.
# Remaining args are left in ARGS array for the caller.
ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform) PLATFORM="$2"; shift 2 ;;
    *) ARGS+=("$1"); shift ;;
  esac
done
set -- "${ARGS[@]+"${ARGS[@]}"}"

# Auto-detect platform: linux/amd64 on macOS, native on Linux.
if [[ -z "$PLATFORM" ]]; then
  if [[ "$(uname -s)" == "Darwin" ]]; then
    PLATFORM="linux/amd64"
  else
    PLATFORM="linux/$(uname -m)"
  fi
fi
