#!/bin/bash
#
# Builds a Debian Trixie container and runs the dotfiles setup inside it.
# Output is captured to test/.output/ with a timestamped filename.
#
set -o nounset -o errexit -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

IMAGE_NAME="dotfiles-test-trixie"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
TIMESTAMP="$(date +%Y-%m-%dT%H%M%S)"
OUTPUT_DIR="$SCRIPT_DIR/.output"
LOG_FILE="$OUTPUT_DIR/$TIMESTAMP.log"

mkdir -p "$OUTPUT_DIR"

echo "Building test image (uid=$HOST_UID, gid=$HOST_GID)..."
docker build \
  --build-arg HOST_UID="$HOST_UID" \
  --build-arg HOST_GID="$HOST_GID" \
  -t "$IMAGE_NAME" \
  "$SCRIPT_DIR"

echo "Running test container..."
echo "Log file: $LOG_FILE"

set +o errexit
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "Error: SSH key not found at $SSH_KEY"
  exit 1
fi

docker run --rm -t \
  -e IN_CONTAINER=true \
  -v "$REPO_DIR:/home/tester/dotfiles" \
  -v "$SSH_KEY:/home/tester/.ssh/id_ed25519:ro" \
  "$IMAGE_NAME" \
  bash -c 'ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null && bash ~/dotfiles/setup' 2>&1 | tee "$LOG_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -o errexit

echo ""
if [ $EXIT_CODE -eq 0 ]; then
  echo "Test completed successfully."
else
  echo "Test completed with exit code $EXIT_CODE (some tasks may have failed)."
fi
echo "Full output saved to: $LOG_FILE"
exit $EXIT_CODE
