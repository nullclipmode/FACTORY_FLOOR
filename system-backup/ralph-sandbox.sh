#!/usr/bin/env bash
# ralph-sandbox.sh - Hardened AFK Ralph (v3)
# Run Ralph in a container with minimal access to host system

set -euo pipefail

: "${GITHUB_TOKEN:?GITHUB_TOKEN not set}"
: "${ANTHROPIC_API_KEY:?ANTHROPIC_API_KEY not set}"

APP_DIR="${1:-.}"
APP_DIR="$(cd "$APP_DIR" && pwd -P)"

# Optional: bridge|none (default bridge)
SANDBOX_NETWORK="${SANDBOX_NETWORK:-bridge}"

NETRC_TMP=""
ORIGINAL_REMOTE=""
NEEDS_REMOTE_REWRITE=false

cleanup() {
  [[ -n "${NETRC_TMP}" ]] && rm -f "${NETRC_TMP}" || true
  if [[ "${NEEDS_REMOTE_REWRITE}" == true && -n "${ORIGINAL_REMOTE}" ]]; then
    git -C "$APP_DIR" remote set-url origin "$ORIGINAL_REMOTE" || true
    echo "Restored original remote"
  fi
}
trap cleanup EXIT

# Extract repo path and ensure HTTPS remote
pushd "$APP_DIR" >/dev/null
REMOTE_URL="$(git remote get-url origin 2>/dev/null || echo "")"
ORIGINAL_REMOTE="$REMOTE_URL"
REPO_PATH=""

if [[ -n "$REMOTE_URL" ]]; then
  if [[ "$REMOTE_URL" == git@github.com:* ]]; then
    REPO_PATH="${REMOTE_URL#git@github.com:}"
    NEEDS_REMOTE_REWRITE=true
  elif [[ "$REMOTE_URL" == ssh://git@github.com/* ]]; then
    REPO_PATH="${REMOTE_URL#ssh://git@github.com/}"
    NEEDS_REMOTE_REWRITE=true
  elif [[ "$REMOTE_URL" == https://*github.com/* ]]; then
    REPO_PATH="${REMOTE_URL#https://}"
    REPO_PATH="${REPO_PATH#*github.com/}"
  fi
  REPO_PATH="${REPO_PATH%.git}"
fi

if [[ -z "$REPO_PATH" ]]; then
  echo "Could not extract repo path from remote: $REMOTE_URL" >&2
  exit 1
fi

if [[ "$NEEDS_REMOTE_REWRITE" == true ]]; then
  echo "Temporarily rewriting SSH remote to HTTPS for container auth"
  git remote set-url origin "https://github.com/${REPO_PATH}.git"
fi
popd >/dev/null

echo "Repo: github.com/${REPO_PATH}"

# Temp .netrc on host, bind-mounted read-only into container
NETRC_TMP="$(mktemp)"
cat >"$NETRC_TMP" <<EOF
machine github.com
login x-access-token
password ${GITHUB_TOKEN}
EOF
chmod 600 "$NETRC_TMP"

UID_HOST="$(id -u)"
GID_HOST="$(id -g)"
TS="$(date +%Y%m%d-%H%M%S)"

docker run --rm \
  --init \
  --read-only \
  --network="$SANDBOX_NETWORK" \
  --tmpfs /tmp:nosuid,nodev,size=512m,uid="$UID_HOST",gid="$GID_HOST",mode=1777 \
  --tmpfs /home/claude:nosuid,nodev,size=256m,uid="$UID_HOST",gid="$GID_HOST",mode=700 \
  --user "$UID_HOST:$GID_HOST" \
  -e HOME=/home/claude \
  -e GIT_TERMINAL_PROMPT=0 \
  -e GIT_ASKPASS=/bin/false \
  -v "$NETRC_TMP":/home/claude/.netrc:ro \
  --cap-drop=ALL \
  --security-opt=no-new-privileges \
  --pids-limit=256 \
  --memory=4g \
  --cpus=2 \
  -v "$APP_DIR":/workspace \
  -w /workspace \
  -e ANTHROPIC_API_KEY \
  claude-ralph:latest \
  ./ralph-loop.sh 2>&1 | tee "$APP_DIR/ralph-${TS}.log"
