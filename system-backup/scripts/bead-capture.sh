#!/bin/bash
# bead-capture.sh - Capture errors as beads automatically
#
# Usage:
#   bead-capture.sh build "Build failed: error message"
#   bead-capture.sh test "Test failed: test name"
#   bead-capture.sh runtime "Runtime error: details"
#   bead-capture.sh manual "Title" "Description"
#
# Integrates with Ralph loop via auto-fix label (for full automation)
# or creates without label (for manual review first)

set -euo pipefail

BD="${HOME}/.local/bin/bd"
TYPE="${1:-manual}"
TITLE="${2:-Untitled issue}"
DESCRIPTION="${3:-}"
AUTO_FIX="${AUTO_FIX:-false}"

# Check bd is available
if ! command -v "$BD" &> /dev/null; then
    echo "ERROR: bd not found at $BD"
    exit 1
fi

# Check we're in a beads-enabled directory
if [ ! -d ".beads" ]; then
    echo "ERROR: Not in a beads-enabled directory. Run 'bd init' first."
    exit 1
fi

# Determine priority based on type
case "$TYPE" in
    build)
        PRIORITY=0  # P0 - Critical
        LABELS="build-failure,automated"
        ;;
    test)
        PRIORITY=1  # P1 - High
        LABELS="test-failure,automated"
        ;;
    runtime)
        PRIORITY=0  # P0 - Critical
        LABELS="runtime-error,automated"
        ;;
    security)
        PRIORITY=0  # P0 - Critical
        LABELS="security,automated"
        ;;
    manual)
        PRIORITY=2  # P2 - Medium
        LABELS="manual"
        ;;
    *)
        PRIORITY=2
        LABELS="automated"
        ;;
esac

# Add auto-fix label if enabled
if [ "$AUTO_FIX" = "true" ]; then
    LABELS="${LABELS},auto-fix"
fi

# Create the bead
BEAD_OUTPUT=$("$BD" create "$TITLE" -p "$PRIORITY" --json 2>&1)
BEAD_ID=$(echo "$BEAD_OUTPUT" | jq -r '.id // empty' 2>/dev/null || echo "")

if [ -z "$BEAD_ID" ]; then
    echo "ERROR: Failed to create bead"
    echo "$BEAD_OUTPUT"
    exit 1
fi

# Add labels
IFS=',' read -ra LABEL_ARRAY <<< "$LABELS"
for label in "${LABEL_ARRAY[@]}"; do
    "$BD" label add "$BEAD_ID" "$label" 2>/dev/null || true
done

# Add description if provided
if [ -n "$DESCRIPTION" ]; then
    "$BD" update "$BEAD_ID" --description "$DESCRIPTION" 2>/dev/null || true
fi

# Output result
echo "Created bead: $BEAD_ID"
echo "  Title: $TITLE"
echo "  Priority: P$PRIORITY"
echo "  Labels: $LABELS"
if [ "$AUTO_FIX" = "true" ]; then
    echo "  Mode: AUTO-FIX (will be processed by bead-watcher)"
else
    echo "  Mode: MANUAL (use /fix-bead $BEAD_ID to process)"
fi

# Sync to git
"$BD" sync 2>/dev/null || echo "Warning: bd sync failed"
