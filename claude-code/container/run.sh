#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-sandbox"
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"
PROJECTS_DIR="$HOME/projects"

# --- Parse script flags (before -- or claude args) ---
FORCE_BUILD=false
CLAUDE_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --build)
            FORCE_BUILD=true
            shift
            ;;
        *)
            CLAUDE_ARGS+=("$1")
            shift
            ;;
    esac
done

# --- Build image if needed ---
BUILD_TAG="${IMAGE_NAME}:uid${HOST_UID}"

if [[ "$FORCE_BUILD" == true ]] || ! docker image inspect "${BUILD_TAG}" &>/dev/null; then
    echo "Building Claude sandbox image (${BUILD_TAG})..."
    docker build \
        --build-arg USER_UID="${HOST_UID}" \
        --build-arg USER_GID="${HOST_GID}" \
        -t "${BUILD_TAG}" \
        "${SCRIPT_DIR}"
fi

# --- Auth resolution ---
AUTH_ARGS=()

if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    AUTH_ARGS+=(-e "ANTHROPIC_API_KEY")
elif [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
    AUTH_ARGS+=(-e "ANTHROPIC_AUTH_TOKEN")
elif [[ -f "${HOME}/.claude/.credentials.json" ]]; then
    : # credentials will be available via the ~/.claude mount below
else
    echo "ERROR: No auth credentials found." >&2
    echo "  The macOS Keychain is not accessible inside a container." >&2
    echo "  Provide credentials via one of:" >&2
    echo "    1. Run 'claude setup-token' on the host to create ~/.claude/.credentials.json" >&2
    echo "    2. Set ANTHROPIC_API_KEY environment variable" >&2
    echo "    3. Set ANTHROPIC_AUTH_TOKEN environment variable" >&2
    exit 1
fi

# --- Volume mounts ---
MOUNT_ARGS=(
    # Always mount the projects tree
    -v "${PROJECTS_DIR}:${PROJECTS_DIR}"
    # Share Claude config, settings, and credentials
    -v "${HOME}/.claude:/home/claude/.claude"
)

# Mount .claude.json (main config with auth) if it exists
[[ -f "${HOME}/.claude.json" ]] && MOUNT_ARGS+=(-v "${HOME}/.claude.json:/home/claude/.claude.json")

# If pwd is outside $HOME/projects, add an extra mount
CURRENT_DIR="$(pwd)"
case "${CURRENT_DIR}" in
    "${PROJECTS_DIR}"*)
        # pwd is inside projects — already covered
        ;;
    *)
        MOUNT_ARGS+=(-v "${CURRENT_DIR}:${CURRENT_DIR}")
        ;;
esac

# Git and SSH config (mount only if they exist)
[[ -f "${HOME}/.gitconfig" ]] && MOUNT_ARGS+=(-v "${HOME}/.gitconfig:/home/claude/.gitconfig:ro")
[[ -d "${HOME}/.ssh" ]] && MOUNT_ARGS+=(-v "${HOME}/.ssh:/home/claude/.ssh:ro")

# --- Security ---
SECURITY_ARGS=(
    --cap-drop ALL
    --security-opt no-new-privileges
)

# --- Run ---
exec docker run \
    --rm \
    -it \
    -w "${CURRENT_DIR}" \
    "${MOUNT_ARGS[@]}" \
    "${AUTH_ARGS[@]}" \
    "${SECURITY_ARGS[@]}" \
    -e TERM="${TERM:-xterm-256color}" \
    "${BUILD_TAG}" \
    --dangerously-skip-permissions \
    "${CLAUDE_ARGS[@]}"
