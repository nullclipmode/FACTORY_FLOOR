#!/bin/bash

# plan-to-beads.sh - Convert IMPLEMENTATION_PLAN.md to beads
# Usage: plan-to-beads.sh [plan-file] [parent-label]

PLAN_FILE="${1:-./IMPLEMENTATION_PLAN.md}"
PARENT_LABEL="${2:-ralph}"

if [ ! -f "$PLAN_FILE" ]; then
    echo "Error: Plan file not found: $PLAN_FILE"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Extract task name from plan header
TASK_NAME=$(grep -m1 "^Task:" "$PLAN_FILE" | sed 's/Task: //')
if [ -z "$TASK_NAME" ]; then
    TASK_NAME="Ralph task $(date +%Y%m%d-%H%M)"
fi

echo -e "${YELLOW}Converting plan to beads...${NC}"
echo "Task: $TASK_NAME"
echo "---"

# Create parent bead for the whole task
PARENT_ID=$(bd create "$TASK_NAME" --label "$PARENT_LABEL" --json 2>/dev/null | jq -r '.id')
if [ -z "$PARENT_ID" ] || [ "$PARENT_ID" = "null" ]; then
    echo "Error: Failed to create parent bead"
    exit 1
fi
echo -e "${GREEN}Created parent bead: $PARENT_ID${NC}"

# Track previous step for dependencies
PREV_BEAD_ID=""
STEP_COUNT=0

# Parse steps using awk for reliability
# Format: Step N: Title
#         - Task: description
#         - Done: criteria
#         - Review: AUTO | HITL

awk '
/^Step [0-9]+:/ {
    if (title != "") {
        # Output previous step
        print title "|" task "|" done "|" review
    }
    title = substr($0, index($0, ":") + 2)
    task = ""
    done = ""
    review = "AUTO"
}
/^- Task:/ { task = substr($0, 9) }
/^- Done:/ { done = substr($0, 8) }
/^- Review:/ {
    r = substr($0, 10)
    gsub(/^[ \t]+|[ \t]+$/, "", r)
    review = r
}
END {
    if (title != "") {
        print title "|" task "|" done "|" review
    }
}
' "$PLAN_FILE" | while IFS='|' read -r STEP_TITLE STEP_TASK STEP_DONE STEP_REVIEW; do
    [ -z "$STEP_TITLE" ] && continue

    # Build bd create command
    BD_ARGS=("$STEP_TITLE")

    # Add acceptance criteria if we have Done field
    if [ -n "$STEP_DONE" ]; then
        BD_ARGS+=(--acceptance "$STEP_DONE")
    fi

    # Add description from Task field
    if [ -n "$STEP_TASK" ]; then
        BD_ARGS+=(--description "$STEP_TASK")
    fi

    # Add labels
    if [ "$STEP_REVIEW" = "HITL" ]; then
        BD_ARGS+=(--label hitl)
    else
        BD_ARGS+=(--label auto-fix)
    fi
    BD_ARGS+=(--label "$PARENT_LABEL")

    # Add dependency on previous step (read from temp file)
    if [ -f /tmp/prev_bead_id ]; then
        PREV_BEAD_ID=$(cat /tmp/prev_bead_id)
        if [ -n "$PREV_BEAD_ID" ]; then
            BD_ARGS+=(--deps "blocks:$PREV_BEAD_ID")
        fi
    fi

    # Create the bead
    BEAD_JSON=$(bd create "${BD_ARGS[@]}" --json 2>/dev/null)
    BEAD_ID=$(echo "$BEAD_JSON" | jq -r '.id')

    if [ -n "$BEAD_ID" ] && [ "$BEAD_ID" != "null" ]; then
        STEP_COUNT=$((STEP_COUNT + 1))
        echo "$BEAD_ID" > /tmp/prev_bead_id
        REVIEW_TAG=""
        [ "$STEP_REVIEW" = "HITL" ] && REVIEW_TAG=" [HITL]"
        echo -e "${GREEN}  $BEAD_ID: $STEP_TITLE$REVIEW_TAG${NC}"
    else
        echo "Warning: Failed to create bead for: $STEP_TITLE"
    fi
done

# Clean up
rm -f /tmp/prev_bead_id

# Count beads created
FINAL_COUNT=$(bd list --label "$PARENT_LABEL" --status open --json 2>/dev/null | jq -r 'length')
echo "---"
echo -e "${GREEN}Created $FINAL_COUNT beads under parent $PARENT_ID${NC}"
echo ""
echo "Next steps:"
echo "  bd list --label $PARENT_LABEL   # See all steps"
echo "  bd ready                        # Find runnable steps"
echo "  ralph-loop.sh                   # Start building"
