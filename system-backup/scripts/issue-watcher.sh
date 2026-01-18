#!/bin/bash
# issue-watcher.sh - Minimal Linear poller for auto-fix issues
#
# Run via cron: */5 * * * * ~/.claude/scripts/issue-watcher.sh
#
# Single responsibility:
# 1. Find issues with auto-fix label
# 2. Call /fix-issue for each
# No logic. No intelligence.

set -euo pipefail

LOG_FILE="${HOME}/.claude/logs/issue-watcher.log"
LOCK_FILE="${HOME}/.claude/locks/issue-watcher.lock"
LINEAR_TEAM="${LINEAR_TEAM:-}" # Set your team ID

mkdir -p "$(dirname "$LOG_FILE")"
mkdir -p "$(dirname "$LOCK_FILE")"

log() {
    echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $1" >> "$LOG_FILE"
}

# Prevent concurrent runs
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE")
    if ps -p "$pid" > /dev/null 2>&1; then
        log "Already running (PID: $pid). Exiting."
        exit 0
    fi
    rm "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

log "Starting issue watcher"

# Check Linear CLI is available
if ! command -v linear &> /dev/null; then
    log "ERROR: Linear CLI not found"
    exit 1
fi

# Get issues with auto-fix label
# Note: Adjust this query based on Linear CLI/API
issues=$(linear issue list --label "auto-fix" --status "Todo,In Progress" --json 2>/dev/null || echo "[]")

if [ "$issues" = "[]" ] || [ -z "$issues" ]; then
    log "No auto-fix issues found"
    exit 0
fi

# Process each issue
echo "$issues" | jq -r '.[].identifier' | while read -r issue_id; do
    if [ -z "$issue_id" ]; then
        continue
    fi

    log "Processing issue: $issue_id"

    # Check if already being processed (has in-progress PR)
    # Skip if PR already exists for this issue
    existing_pr=$(gh pr list --search "$issue_id" --json number --jq 'length' 2>/dev/null || echo "0")
    if [ "$existing_pr" -gt 0 ]; then
        log "Issue $issue_id already has PR. Skipping."
        continue
    fi

    # Call fix-issue via Claude Code
    # This runs in a subshell to isolate failures
    (
        cd "${REPO_PATH:-$(pwd)}"
        log "Running /fix-issue $issue_id"
        claude -p "/fix-issue $issue_id" 2>&1 | tee -a "$LOG_FILE"
    ) || {
        log "ERROR: /fix-issue failed for $issue_id"
    }

    # Rate limit: wait between issues
    sleep 30
done

log "Issue watcher complete"
