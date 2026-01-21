#!/bin/bash

# Ralph Maintenance Runner
# Processes lint/typecheck/test beads with Haiku
# Quick fixes only - no verification loops
#
# Usage:
#   ./ralph-maintenance.sh                    # Process all maintenance beads
#   ./ralph-maintenance.sh class:lint         # Process only lint beads
#   ./ralph-maintenance.sh FF-abc123          # Process specific bead

set -euo pipefail

MAX_ITERATIONS=${RALPH_MAINT_ITERATIONS:-10}
MAINT_CLASSES="class:lint,class:typecheck,class:test"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Argument handling
FILTER="${1:-}"

get_maintenance_beads() {
    if [[ "$FILTER" == *-* ]]; then
        # Specific bead ID
        bd show "$FILTER" --json 2>/dev/null || echo "[]"
    elif [[ -n "$FILTER" ]]; then
        # Specific class label
        bd list --labels "$FILTER" --json 2>/dev/null || echo "[]"
    else
        # All maintenance classes
        bd list --labels "$MAINT_CLASSES" --json 2>/dev/null || echo "[]"
    fi
}

process_bead() {
    local bead_id="$1"
    local bead_title="$2"
    local bead_class="$3"
    local attempt=0

    echo -e "${BLUE}Processing: $bead_id - $bead_title${NC}"
    echo "Class: $bead_class"

    while [ $attempt -lt $MAX_ITERATIONS ]; do
        attempt=$((attempt + 1))
        echo -e "${YELLOW}Attempt $attempt/$MAX_ITERATIONS${NC}"

        # Get full bead details for context
        bead_details=$(bd show "$bead_id" 2>/dev/null || echo "")

        # Build prompt based on class
        case "$bead_class" in
            class:lint)
                fix_cmd="npm run lint"
                prompt="Fix the lint errors described in this bead. Run '$fix_cmd' to verify fix."
                ;;
            class:typecheck)
                fix_cmd="npm run typecheck"
                prompt="Fix the TypeScript errors described in this bead. Run '$fix_cmd' to verify fix."
                ;;
            class:test)
                fix_cmd="npm test"
                prompt="Fix the test failures described in this bead. Run '$fix_cmd' to verify fix."
                ;;
            *)
                echo -e "${RED}Unknown class: $bead_class${NC}"
                return 1
                ;;
        esac

        # Run fix with Haiku
        fix_prompt="BEAD: $bead_id
TITLE: $bead_title
DETAILS:
$bead_details

$prompt

Output <fixed>SUCCESS</fixed> if the issue is resolved.
Output <fixed>FAILED</fixed> if you cannot resolve it."

        result=$(echo "$fix_prompt" | claude -p \
            --model claude-3-5-haiku-latest \
            --allowedTools "Read Edit Write Bash Glob Grep" \
            --dangerously-skip-permissions 2>&1)

        echo "$result"

        if echo "$result" | grep -q "<fixed>SUCCESS</fixed>"; then
            echo -e "${GREEN}Fixed! Closing bead.${NC}"
            bd close "$bead_id" --comment "Auto-fixed by maintenance runner"
            return 0
        fi

        if echo "$result" | grep -q "<fixed>FAILED</fixed>"; then
            echo -e "${YELLOW}Could not fix, will retry...${NC}"
            sleep 1
            continue
        fi

        # Unclear result, continue
        sleep 1
    done

    echo -e "${RED}Could not fix after $MAX_ITERATIONS attempts.${NC}"
    bd label add "$bead_id" "needs-human"
    return 1
}

# Main
echo -e "${BLUE}=== MAINTENANCE RUNNER ===${NC}"
echo "Max iterations per bead: $MAX_ITERATIONS"

beads_json=$(get_maintenance_beads)
bead_count=$(echo "$beads_json" | jq 'length' 2>/dev/null || echo "0")

if [ "$bead_count" = "0" ]; then
    echo -e "${GREEN}No maintenance beads found.${NC}"
    exit 0
fi

echo "Found $bead_count maintenance bead(s)"
echo "---"

# Process each bead
echo "$beads_json" | jq -c '.[]' | while read -r bead; do
    bead_id=$(echo "$bead" | jq -r '.id')
    bead_title=$(echo "$bead" | jq -r '.title')
    # Extract class label
    bead_class=$(echo "$bead" | jq -r '.labels[]? | select(startswith("class:"))' | head -1)

    if [ -z "$bead_class" ]; then
        echo -e "${YELLOW}Skipping $bead_id - no class label${NC}"
        continue
    fi

    process_bead "$bead_id" "$bead_title" "$bead_class" || true
    echo "---"
done

echo -e "${GREEN}Maintenance run complete.${NC}"
