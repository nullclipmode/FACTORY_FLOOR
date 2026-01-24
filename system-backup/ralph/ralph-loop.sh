#!/bin/bash

# Ralph Loop - Fresh context orchestrator with bead tracking
# Uses native Claude Code subagents for isolated context windows
#
# Two modes:
#   ./ralph-loop.sh plan "task description"  - Create plan + beads
#   ./ralph-loop.sh                          - Execute beads

PLAN_TO_BEADS="$HOME/.claude/plan-to-beads.sh"
PLAN_FILE="./IMPLEMENTATION_PLAN.md"
RALPH_LABEL="ralph"
MAX_RETRIES=10
VERIFY_RETRIES=5
REVIEW_RETRIES=3
REPLAN_AFTER=5
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-50}
MAX_BEAD_ATTEMPTS=3

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Mode detection
MODE="${1:-build}"
TASK="${2:-}"

if [ "$MODE" = "plan" ]; then
    # PLAN MODE - Create implementation plan + convert to beads
    if [ -z "$TASK" ]; then
        echo -e "${RED}Error: Plan mode requires a task description${NC}"
        echo "Usage: ./ralph-loop.sh plan \"Add user authentication\""
        exit 1
    fi

    echo -e "${BLUE}=== PLAN MODE ===${NC}"
    echo "Task: $TASK"
    echo "---"

    # Invoke ralph-planner subagent
    PLAN_PROMPT="Use the ralph-planner subagent to create an implementation plan for this task:

TASK: $TASK

Create IMPLEMENTATION_PLAN.md with test-first phases as specified in the subagent instructions."

    output=$(echo "$PLAN_PROMPT" | claude -p --allowedTools "Read Glob Grep Bash Task" 2>&1)
    echo "$output"

    if [ -f "$PLAN_FILE" ]; then
        echo -e "${GREEN}Plan created: $PLAN_FILE${NC}"
        echo ""

        # Convert plan to beads
        if [ -f "$PLAN_TO_BEADS" ]; then
            echo -e "${BLUE}Converting plan to beads...${NC}"
            bash "$PLAN_TO_BEADS" "$PLAN_FILE" "$RALPH_LABEL"
        else
            echo -e "${YELLOW}Warning: plan-to-beads.sh not found, skipping bead creation${NC}"
        fi

        echo ""
        echo "Next: Run ./ralph-loop.sh to execute"
    else
        echo -e "${RED}Failed to create plan${NC}"
        exit 1
    fi
    exit 0
fi

# BUILD MODE - Execute beads
echo -e "${BLUE}=== BUILD MODE ===${NC}"
echo "Max iterations: $MAX_ITERATIONS (set RALPH_MAX_ITERATIONS to change)"

# Check for ralph beads
RALPH_BEADS=$(bd list --label "$RALPH_LABEL" --status open --json 2>/dev/null | jq -r 'length')
if [ "$RALPH_BEADS" = "0" ] || [ -z "$RALPH_BEADS" ]; then
    # Fallback: check for IMPLEMENTATION_PLAN.md without beads
    if [ -f "$PLAN_FILE" ]; then
        echo -e "${YELLOW}No ralph beads found. Converting plan to beads...${NC}"
        if [ -f "$PLAN_TO_BEADS" ]; then
            bash "$PLAN_TO_BEADS" "$PLAN_FILE" "$RALPH_LABEL"
        else
            echo -e "${RED}Error: No beads and no plan-to-beads.sh${NC}"
            echo "Run: ./ralph-loop.sh plan \"your task\""
            exit 1
        fi
    else
        echo -e "${RED}Error: No ralph beads found${NC}"
        echo "Run: ./ralph-loop.sh plan \"your task\""
        exit 1
    fi
fi

retry_count=0
current_bead_id=""
bead_total_attempts=0
iteration=0

# Capture closed beads state for immutability check
# Closed beads must not be deleted or modified during the loop
CLOSED_BEADS_JSON=$(bd list --status closed --json 2>/dev/null || echo "[]")

# Function to verify closed bead immutability (handles spaces in IDs)
check_closed_bead_immutability() {
    local current_json
    current_json=$(bd list --status closed --json 2>/dev/null || echo "[]")
    local violations=0

    # Iterate through original closed beads using process substitution
    # This preserves variable scope and handles spaces in IDs
    while IFS= read -r CID; do
        [ -z "$CID" ] && continue

        # Use jq --arg to safely handle special characters in ID
        OLD_BEAD=$(echo "$CLOSED_BEADS_JSON" | jq -c --arg id "$CID" '.[] | select(.id == $id)' 2>/dev/null)
        NEW_BEAD=$(echo "$current_json" | jq -c --arg id "$CID" '.[] | select(.id == $id)' 2>/dev/null)

        if [ -z "$NEW_BEAD" ]; then
            echo -e "${RED}BLOCKED: Closed bead $CID was deleted${NC}"
            violations=$((violations + 1))
        elif [ "$OLD_BEAD" != "$NEW_BEAD" ]; then
            echo -e "${RED}BLOCKED: Closed bead $CID was modified${NC}"
            echo "  Old: $OLD_BEAD"
            echo "  New: $NEW_BEAD"
            violations=$((violations + 1))
        fi
    done < <(echo "$CLOSED_BEADS_JSON" | jq -r '.[].id' 2>/dev/null)

    return $violations
}

while true; do
    iteration=$((iteration + 1))

    if [ $iteration -gt $MAX_ITERATIONS ]; then
        echo -e "${RED}Max iterations ($MAX_ITERATIONS) reached. Stopping.${NC}"
        echo "Run 'bd list --label $RALPH_LABEL' to see progress."
        exit 1
    fi

    # Get next runnable bead (open, not blocked by other open beads)
    NEXT_BEAD=$(bd ready --label "$RALPH_LABEL" --json 2>/dev/null | jq -r '.[0] // empty')

    if [ -z "$NEXT_BEAD" ]; then
        # Check if there are any open beads at all
        OPEN_COUNT=$(bd list --label "$RALPH_LABEL" --status open --json 2>/dev/null | jq -r 'length')
        if [ "$OPEN_COUNT" = "0" ] || [ -z "$OPEN_COUNT" ]; then
            echo -e "${GREEN}All ralph beads complete!${NC}"
            exit 0
        else
            # Beads exist but none ready - likely blocked
            echo -e "${YELLOW}No runnable beads. $OPEN_COUNT beads blocked or waiting.${NC}"
            echo "Run 'bd list --label $RALPH_LABEL --status open' to see blocked beads."
            exit 2
        fi
    fi

    BEAD_ID=$(echo "$NEXT_BEAD" | jq -r '.id')
    BEAD_TITLE=$(echo "$NEXT_BEAD" | jq -r '.title')
    BEAD_DESC=$(echo "$NEXT_BEAD" | jq -r '.description // empty')
    BEAD_ACCEPTANCE=$(echo "$NEXT_BEAD" | jq -r '.acceptance // empty')
    IS_HITL=$(echo "$NEXT_BEAD" | jq -r '.labels | if . then (. | index("hitl") != null) else false end')

    # Check if this is a HITL bead
    if [ "$IS_HITL" = "true" ]; then
        echo -e "${YELLOW}=== HITL: Human review required ===${NC}"
        echo "Bead: $BEAD_ID - $BEAD_TITLE"
        [ -n "$BEAD_DESC" ] && echo "Description: $BEAD_DESC"
        echo ""
        echo -e "${YELLOW}Run: /hitl-approve $BEAD_ID${NC}"
        echo ""
        echo -e "${BLUE}Current bead state:${NC}"
        bd prime 2>/dev/null
        exit 2
    fi

    if [ "$BEAD_ID" != "$current_bead_id" ]; then
        current_bead_id="$BEAD_ID"
        retry_count=0
        bead_total_attempts=0
        # Mark as in_progress
        bd update "$BEAD_ID" --status in_progress 2>/dev/null
    fi

    # Check total attempts BEFORE incrementing (Option B - prevents off-by-one)
    if [ "$bead_total_attempts" -ge "$MAX_BEAD_ATTEMPTS" ]; then
        echo -e "${RED}Bead failed after $MAX_BEAD_ATTEMPTS full cycles${NC}"
        bd update "$BEAD_ID" --status blocked 2>/dev/null
        bd label add "$BEAD_ID" hitl 2>/dev/null
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        LAST_OUTPUT=$(echo "$output" | tail -c 500)
        bd comments add "$BEAD_ID" "[$BEAD_ID] [$TIMESTAMP] [BUILD] Failed after $MAX_BEAD_ATTEMPTS full cycles.
Last output:
$LAST_OUTPUT" 2>/dev/null
        echo -e "${YELLOW}Bead $BEAD_ID marked blocked + hitl${NC}"
        echo ""
        echo -e "${BLUE}Current bead state:${NC}"
        bd prime 2>/dev/null
        exit 2
    fi
    bead_total_attempts=$((bead_total_attempts + 1))

    echo -e "${YELLOW}Running Ralph Builder (attempt $((retry_count + 1))/$MAX_RETRIES)...${NC}"
    echo "Bead: $BEAD_ID - $BEAD_TITLE"
    [ -n "$BEAD_ACCEPTANCE" ] && echo "Acceptance: $BEAD_ACCEPTANCE"
    echo "---"

    # Inject context files so Claude starts with full context
    [ -f ./AGENTS.md ] || cp ~/.claude/AGENTS.md ./AGENTS.md 2>/dev/null || touch ./AGENTS.md

    # Invoke ralph-builder subagent
    BUILD_PROMPT="Use the ralph-builder subagent to implement this bead.

Current task bead:
ID: $BEAD_ID
Title: $BEAD_TITLE
Description: $BEAD_DESC
Acceptance criteria: $BEAD_ACCEPTANCE

Complete this task following test-first principles. Output <promise>DONE</promise> when finished or <promise>FAILED</promise> if blocked."

    output=$(echo "$BUILD_PROMPT" | claude -p --allowedTools "Read Edit Write Bash Glob Grep Task" --dangerously-skip-permissions 2>&1)
    echo "$output"

    if echo "$output" | grep -q "<promise>DONE</promise>"; then
        echo -e "${GREEN}Step completed! Running verification...${NC}"

        # Invoke ralph-verifier subagent
        verify_attempt=0
        while [ $verify_attempt -lt $VERIFY_RETRIES ]; do
            echo -e "${BLUE}Verification attempt $((verify_attempt + 1))/$VERIFY_RETRIES${NC}"

            VERIFY_PROMPT="Use the ralph-verifier subagent to verify the implementation.

Bead being verified:
ID: $BEAD_ID
Title: $BEAD_TITLE
Acceptance criteria: $BEAD_ACCEPTANCE

Check build, tests, and functionality. Output <verify>PASS</verify>, <verify>FAIL:CATEGORY</verify>, or <verify>HITL</verify>."

            verify_result=$(echo "$VERIFY_PROMPT" | claude -p --allowedTools "Read Bash Glob Grep Task" --dangerously-skip-permissions 2>&1)
            echo "$verify_result"

            if echo "$verify_result" | grep -q "<verify>PASS</verify>"; then
                echo -e "${GREEN}Verification passed!${NC}"
                break
            fi

            if echo "$verify_result" | grep -q "<verify>HITL</verify>"; then
                echo -e "${YELLOW}=== HITL: Human review required ===${NC}"
                echo "$verify_result" | grep -A20 "Needs human review:"
                echo ""

                # Update bead to HITL status
                bd label add "$BEAD_ID" hitl 2>/dev/null
                TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                HITL_DETAILS=$(echo "$verify_result" | grep -A20 'Needs human review:')
                bd comments add "$BEAD_ID" "[$BEAD_ID] [$TIMESTAMP] [VERIFY] HITL required.
$HITL_DETAILS" 2>/dev/null
                echo -e "${YELLOW}Bead $BEAD_ID marked for HITL review${NC}"
                echo -e "${YELLOW}Run: /hitl-approve $BEAD_ID${NC}"
                echo ""
                echo -e "${BLUE}Current bead state:${NC}"
                bd prime 2>/dev/null
                exit 2
            fi

            if echo "$verify_result" | grep -q "<verify>FAIL"; then
                verify_attempt=$((verify_attempt + 1))

                if [ $verify_attempt -ge $VERIFY_RETRIES ]; then
                    echo -e "${RED}Verification failed - needs fix${NC}"
                    # Capture full structured failure (Acceptance through Confidence)
                    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                    FAIL_DETAILS=$(echo "$verify_result" | sed -n '/<verify>FAIL/,/Confidence:/p')
                    # Fallback: if structured capture empty, use last 4KB
                    [ -z "$FAIL_DETAILS" ] && FAIL_DETAILS=$(echo "$verify_result" | tail -c 4096)
                    bd comments add "$BEAD_ID" "[$BEAD_ID] [$TIMESTAMP] [VERIFY] Failed after $VERIFY_RETRIES attempts.
$FAIL_DETAILS" 2>/dev/null
                    # Don't close bead, loop back to fix
                    continue 2
                fi

                echo -e "${YELLOW}Verification failed, Claude will fix and re-verify...${NC}"

                # Run fixer with the failure context
                fix_prompt="The verification failed with this result:
$verify_result

Fix the issue and update the code. Output <promise>FIXED</promise> when done."
                fix_result=$(echo -e "$fix_prompt" | claude -p --dangerously-skip-permissions 2>&1)
                echo "$fix_result"
            else
                # No clear pass/fail, treat as pass with warning
                echo -e "${YELLOW}Verification unclear, continuing...${NC}"
                break
            fi
        done

        # Invoke ralph-reviewer subagent for code review
        echo -e "${BLUE}Running code review via ralph-reviewer subagent...${NC}"
        review_attempt=0
        while [ $review_attempt -lt $REVIEW_RETRIES ]; do
            # Get the diff of recent changes
            git_diff=$(git diff HEAD~1 2>/dev/null || git diff)

            REVIEW_PROMPT="Use the ralph-reviewer subagent to review these code changes.

Bead context:
ID: $BEAD_ID
Title: $BEAD_TITLE
Acceptance: $BEAD_ACCEPTANCE

Git diff to review:
$git_diff

Output <review>APPROVED</review> or <review>NEEDS_WORK</review> with issues list."

            review_result=$(echo "$REVIEW_PROMPT" | claude -p --allowedTools "Read Bash Glob Grep Task" 2>&1)
            echo "$review_result"

            if echo "$review_result" | grep -q "<review>APPROVED</review>"; then
                echo -e "${GREEN}Code review passed!${NC}"
                break
            fi

            if echo "$review_result" | grep -q "<review>NEEDS_WORK</review>"; then
                review_attempt=$((review_attempt + 1))

                if [ $review_attempt -ge $REVIEW_RETRIES ]; then
                    echo -e "${RED}Review failed after $REVIEW_RETRIES attempts - moving on with warning${NC}"
                    break
                fi

                echo -e "${YELLOW}Review found issues, fixing...${NC}"
                fix_prompt="Code review found issues:
$review_result

Fix these issues. Output <promise>FIXED</promise> when done."
                fix_result=$(echo -e "$fix_prompt" | claude -p --dangerously-skip-permissions 2>&1)
                echo "$fix_result"
            else
                echo -e "${YELLOW}Review unclear, continuing...${NC}"
                break
            fi
        done

        # ========== ENFORCED COMMIT GATE (Claude cannot bypass) ==========
        has(){ grep -q "\"$1\"" package.json 2>/dev/null; }

        PASS=true
        if [ -f package.json ]; then
          PM=npm; [ -f pnpm-lock.yaml ] && PM=pnpm; [ -f yarn.lock ] && PM=yarn
          has typecheck && { $PM run typecheck || PASS=false; }
          has lint      && { $PM run lint      || PASS=false; }
          has test      && { $PM run test      || PASS=false; }
          has build     && { $PM run build     || PASS=false; }
        fi

        if [ "$PASS" = false ]; then
          echo -e "${RED}Commit gate failed - looping to fix${NC}"
          continue
        fi

        git add -A
        if git diff --cached --quiet; then
          echo -e "${YELLOW}Nothing staged - skipping commit.${NC}"
        else
          git commit -m "ralph: $BEAD_TITLE [$BEAD_ID]"
          echo -e "${GREEN}Committed.${NC}"
        fi
        # ========== END COMMIT GATE ==========

        # ========== CLOSED BEAD IMMUTABILITY CHECK ==========
        if ! check_closed_bead_immutability; then
            echo -e "${RED}Closed bead immutability violated - aborting${NC}"
            echo "Closed beads must not be deleted or modified during execution."
            exit 1
        fi
        # ========== END IMMUTABILITY CHECK ==========

        # Close the bead
        bd close "$BEAD_ID" --reason "Completed by ralph-loop" 2>/dev/null
        echo -e "${GREEN}Bead $BEAD_ID closed${NC}"

        retry_count=0
        continue
    fi

    if echo "$output" | grep -q "<promise>FAILED</promise>"; then
        retry_count=$((retry_count + 1))

        if [ $retry_count -ge $MAX_RETRIES ]; then
            echo -e "${RED}Bead failed $MAX_RETRIES times.${NC}"
            bd update "$BEAD_ID" --status blocked 2>/dev/null
            TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
            LAST_OUTPUT=$(echo "$output" | tail -c 500)
            bd comments add "$BEAD_ID" "[$BEAD_ID] [$TIMESTAMP] [BUILD] Explicit FAILED after $MAX_RETRIES attempts.
Last output:
$LAST_OUTPUT" 2>/dev/null
            echo -e "${YELLOW}Bead $BEAD_ID marked as blocked${NC}"

            # Reset for next bead
            retry_count=0
            current_bead_id=""
            continue
        fi

        echo -e "${YELLOW}Retrying with fresh context...${NC}"
        sleep 1
        continue
    fi

    retry_count=$((retry_count + 1))

    if [ $retry_count -ge $MAX_RETRIES ]; then
        echo -e "${RED}Bead incomplete after $MAX_RETRIES attempts.${NC}"
        bd update "$BEAD_ID" --status blocked 2>/dev/null
        TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        LAST_OUTPUT=$(echo "$output" | tail -c 500)
        bd comments add "$BEAD_ID" "[$BEAD_ID] [$TIMESTAMP] [BUILD] Incomplete (no DONE/FAILED) after $MAX_RETRIES attempts.
Last output:
$LAST_OUTPUT" 2>/dev/null
        echo -e "${YELLOW}Bead $BEAD_ID marked as blocked${NC}"

        # Reset for next bead
        retry_count=0
        current_bead_id=""
        continue
    fi

    sleep 1
done
