#!/bin/bash
# bead-watcher.sh - Watch for auto-fix beads and process them
#
# Run via cron: */5 * * * * ~/.claude/scripts/bead-watcher.sh
#
# Modes:
#   - auto-fix label: Full automation (no approval)
#   - ready (no auto-fix): Manual approval required
#
# This script only processes beads with 'auto-fix' label automatically.
# For manual processing, use /fix-bead directly.

set -euo pipefail

BD="${HOME}/.local/bin/bd"
LOG_FILE="${HOME}/.claude/logs/bead-watcher.log"
LOCK_FILE="${HOME}/.claude/locks/bead-watcher.lock"

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

log "Starting bead watcher"

# Check bd is available
if ! command -v "$BD" &> /dev/null; then
    log "ERROR: bd not found at $BD"
    exit 1
fi

# Check we're in a beads-enabled directory
if [ ! -d ".beads" ]; then
    log "ERROR: Not in a beads-enabled directory (no .beads/)"
    exit 1
fi

# Get beads with auto-fix label that are ready
# ready = no blockers, status is open or in_progress
beads=$("$BD" ready --json 2>/dev/null || echo "[]")

if [ "$beads" = "[]" ] || [ -z "$beads" ]; then
    log "No ready beads found"
    exit 0
fi

# Filter for auto-fix label, EXCLUDE hitl beads
# HITL beads require human approval - never auto-process them
auto_fix_beads=$(echo "$beads" | jq -r '.[] | select(.labels[]? == "auto-fix") | select((.labels[]? == "hitl") | not) | .id' 2>/dev/null || echo "")

# Count HITL beads for logging
hitl_count=$(echo "$beads" | jq -r '[.[] | select(.labels[]? == "hitl")] | length' 2>/dev/null || echo "0")

if [ -z "$auto_fix_beads" ]; then
    log "No auto-fix beads found ($(echo "$beads" | jq length) ready, $hitl_count HITL awaiting human)"
    exit 0
fi

# Process each auto-fix bead
echo "$auto_fix_beads" | while read -r bead_id; do
    if [ -z "$bead_id" ]; then
        continue
    fi

    log "Processing auto-fix bead: $bead_id"

    # Check if already being processed (has in-progress PR)
    existing_pr=$(gh pr list --search "$bead_id" --json number --jq 'length' 2>/dev/null || echo "0")
    if [ "$existing_pr" -gt 0 ]; then
        log "Bead $bead_id already has PR. Skipping."
        continue
    fi

    # Check attempt count
    attempts=$("$BD" show "$bead_id" --json | jq -r '.labels[]? | select(startswith("ralph-attempts:")) | split(":")[1] // "0"' 2>/dev/null | head -1 || echo "0")
    attempts=${attempts:-0}

    if [ "$attempts" -ge 2 ]; then
        log "Bead $bead_id: Max attempts reached. Adding needs-human label."
        "$BD" label add "$bead_id" needs-human 2>/dev/null || true
        "$BD" label remove "$bead_id" auto-fix 2>/dev/null || true
        continue
    fi

    # Mark as in_progress
    "$BD" update "$bead_id" --status in_progress 2>/dev/null || true

    # Call fix-bead via Claude Code with --auto flag
    (
        log "Running /fix-bead $bead_id --auto"
        claude -p "/fix-bead $bead_id --auto" 2>&1 | tee -a "$LOG_FILE"
    ) || {
        log "ERROR: /fix-bead failed for $bead_id"
        # Increment attempt counter
        new_attempts=$((attempts + 1))
        "$BD" label remove "$bead_id" "ralph-attempts:$attempts" 2>/dev/null || true
        "$BD" label add "$bead_id" "ralph-attempts:$new_attempts" 2>/dev/null || true
    }

    # Rate limit: wait between beads
    sleep 30
done

# Sync beads to git
"$BD" sync 2>/dev/null || log "Warning: bd sync failed"

log "Bead watcher complete"
