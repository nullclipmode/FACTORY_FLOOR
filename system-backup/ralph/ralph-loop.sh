#!/bin/bash

# Ralph Loop - Fresh context orchestrator with bead tracking
# Two modes:
#   ./ralph-loop.sh plan "task description"  - Create plan + beads
#   ./ralph-loop.sh                          - Execute beads

PLAN_PROMPT="$HOME/.claude/ralph-plan-prompt.md"
BUILD_PROMPT="$HOME/.claude/ralph-build-prompt.md"
VERIFY_PROMPT="$HOME/.claude/ralph-verify-prompt.md"
REVIEW_PROMPT="$HOME/.claude/ralph-review-prompt.md"
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

    # Create task context file
    echo "TASK: $TASK" > /tmp/ralph-task.md

    # Run planner with task
    output=$(cat "$PLAN_PROMPT" /tmp/ralph-task.md | claude -p --allowedTools "Read Glob Grep" 2>&1)
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

    echo -e "${YELLOW}Running Ralph (attempt $((retry_count + 1))/$MAX_RETRIES)...${NC}"
    echo "Bead: $BEAD_ID - $BEAD_TITLE"
    [ -n "$BEAD_ACCEPTANCE" ] && echo "Acceptance: $BEAD_ACCEPTANCE"
    echo "---"

    # Inject context files so Claude starts with full context
    [ -f ./AGENTS.md ] || cp ~/.claude/AGENTS.md ./AGENTS.md 2>/dev/null || touch ./AGENTS.md

    # Build context for Claude
    BEAD_CONTEXT="Current task bead:
ID: $BEAD_ID
Title: $BEAD_TITLE
Description: $BEAD_DESC
Acceptance criteria: $BEAD_ACCEPTANCE

Complete this task. Output <promise>DONE</promise> when finished."

    output=$(cat ./AGENTS.md "$BUILD_PROMPT" <(echo "$BEAD_CONTEXT") 2>/dev/null | claude -p --allowedTools "Read Edit Write Bash Glob Grep" --dangerously-skip-permissions 2>&1)
    echo "$output"

    if echo "$output" | grep -q "<promise>DONE</promise>"; then
        echo -e "${GREEN}Step completed! Running verification...${NC}"

        # Autonomous verification with Playwright
        verify_attempt=0
        while [ $verify_attempt -lt $VERIFY_RETRIES ]; do
            echo -e "${BLUE}Verification attempt $((verify_attempt + 1))/$VERIFY_RETRIES${NC}"

            verify_result=$(cat "$VERIFY_PROMPT" | claude -p --dangerously-skip-permissions 2>&1)
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
                    # Capture failure details before looping back
                    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
                    FAIL_DETAILS=$(echo "$verify_result" | grep -A10 '<verify>FAIL')
                    bd comments add "$BEAD_ID" "[$BEAD_ID] [$TIMESTAMP] [VERIFY] Failed after $VERIFY_RETRIES attempts.
$FAIL_DETAILS" 2>/dev/null
                    # Don't close bead, loop back to fix
                    continue 2
                fi

                echo -e "${YELLOW}Verification failed, Claude will fix and re-verify...${NC}"

                # Run fixer with the failure context
                fix_prompt="The verification failed with this result:\n$verify_result\n\nFix the issue and update the code. Output <promise>FIXED</promise> when done."
                fix_result=$(echo -e "$fix_prompt" | claude -p --dangerously-skip-permissions 2>&1)
                echo "$fix_result"
            else
                # No clear pass/fail, treat as pass with warning
                echo -e "${YELLOW}Verification unclear, continuing...${NC}"
                break
            fi
        done

        # Cross-model code review (second opinion)
        if [ -f "$REVIEW_PROMPT" ]; then
            echo -e "${BLUE}Running cross-model review...${NC}"
            review_attempt=0
            while [ $review_attempt -lt $REVIEW_RETRIES ]; do
                # Get the diff of recent changes
                git_diff=$(git diff HEAD~1 2>/dev/null || git diff)
                review_input="$git_diff"

                review_result=$(echo "$review_input" | cat "$REVIEW_PROMPT" - | claude -p 2>&1)
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
                    fix_prompt="Code review found issues:\n$review_result\n\nFix these issues. Output <promise>FIXED</promise> when done."
                    fix_result=$(echo -e "$fix_prompt" | claude -p --dangerously-skip-permissions 2>&1)
                    echo "$fix_result"
                else
                    echo -e "${YELLOW}Review unclear, continuing...${NC}"
                    break
                fi
            done
        fi

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
            bd comments add "$BEAD_ID" "Failed after $MAX_RETRIES attempts" 2>/dev/null
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
        bd comments add "$BEAD_ID" "Incomplete after $MAX_RETRIES attempts" 2>/dev/null
        echo -e "${YELLOW}Bead $BEAD_ID marked as blocked${NC}"

        # Reset for next bead
        retry_count=0
        current_bead_id=""
        continue
    fi

    sleep 1
done
