#!/bin/bash

# Ralph Loop - Fresh context orchestrator
# Two modes:
#   ./ralph-loop.sh plan "task description"  - Create implementation plan
#   ./ralph-loop.sh                          - Execute existing plan

PLAN_PROMPT="$HOME/.claude/ralph-plan-prompt.md"
BUILD_PROMPT="$HOME/.claude/ralph-build-prompt.md"
VERIFY_PROMPT="$HOME/.claude/ralph-verify-prompt.md"
REVIEW_PROMPT="$HOME/.claude/ralph-review-prompt.md"
PLAN_FILE="./IMPLEMENTATION_PLAN.md"
MAX_RETRIES=10
VERIFY_RETRIES=5
REVIEW_RETRIES=3
REPLAN_AFTER=5
MAX_ITERATIONS=${RALPH_MAX_ITERATIONS:-50}  # Total loop iterations before forced stop

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
    # PLAN MODE - Create implementation plan
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
        echo "Next: Run ./ralph-loop.sh to execute"
    else
        echo -e "${RED}Failed to create plan${NC}"
        exit 1
    fi
    exit 0
fi

# BUILD MODE - Execute existing plan
if [ ! -f "$PLAN_FILE" ]; then
    echo -e "${RED}Error: No IMPLEMENTATION_PLAN.md found${NC}"
    echo "Run: ./ralph-loop.sh plan \"your task\""
    exit 1
fi

echo -e "${BLUE}=== BUILD MODE ===${NC}"
echo "Max iterations: $MAX_ITERATIONS (set RALPH_MAX_ITERATIONS to change)"

retry_count=0
current_step=""
iteration=0

while true; do
    iteration=$((iteration + 1))

    if [ $iteration -gt $MAX_ITERATIONS ]; then
        echo -e "${RED}Max iterations ($MAX_ITERATIONS) reached. Stopping.${NC}"
        echo "Progress saved in $PLAN_FILE. Re-run to continue."
        exit 1
    fi
    pending=$(grep -c "Status: PENDING" "$PLAN_FILE" 2>/dev/null | tr -d '\n' || echo "0")

    if [ "$pending" = "0" ] || [ -z "$pending" ]; then
        echo -e "${GREEN}All steps complete!${NC}"
        exit 0
    fi

    new_step=$(grep -B2 "Status: PENDING" "$PLAN_FILE" | head -1)

    if [ "$new_step" != "$current_step" ]; then
        current_step="$new_step"
        retry_count=0
    fi

    echo -e "${YELLOW}Running Ralph (attempt $((retry_count + 1))/$MAX_RETRIES)...${NC}"
    echo "Step: $current_step"
    echo "---"

    output=$(cat "$BUILD_PROMPT" | claude -p --allowedTools "Read Edit Write Bash Glob Grep" --dangerously-skip-permissions 2>&1)
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

            if echo "$verify_result" | grep -q "<verify>FAIL"; then
                verify_attempt=$((verify_attempt + 1))

                if [ $verify_attempt -ge $VERIFY_RETRIES ]; then
                    echo -e "${RED}Verification failed - needs fix${NC}"
                    # Don't mark step complete, loop back to fix
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

        retry_count=0
        continue
    fi

    if echo "$output" | grep -q "<promise>FAILED</promise>"; then
        retry_count=$((retry_count + 1))

        # Auto-replan after REPLAN_AFTER attempts
        if [ $retry_count -eq $REPLAN_AFTER ]; then
            echo -e "${YELLOW}Attempt $REPLAN_AFTER failed. Auto-replanning this step...${NC}"
            replan_prompt="The step '$current_step' has failed $REPLAN_AFTER times. Analyze the errors and rewrite ONLY this step in IMPLEMENTATION_PLAN.md with a different approach. Keep Status: PENDING."
            replan_result=$(echo "$replan_prompt" | claude -p --dangerously-skip-permissions 2>&1)
            echo "$replan_result"
            echo -e "${BLUE}Step replanned. Continuing...${NC}"
            continue
        fi

        if [ $retry_count -ge $MAX_RETRIES ]; then
            echo -e "${RED}Step failed $MAX_RETRIES times (including replan).${NC}"
            echo -e "${YELLOW}Replanning from this step forward...${NC}"

            # Replan only remaining steps - preserve completed work
            replan_full_prompt="A step in IMPLEMENTATION_PLAN.md has failed after $MAX_RETRIES attempts:

BLOCKED STEP: $current_step

Your task:
1. Keep ALL steps marked 'Status: COMPLETE' exactly as they are
2. DELETE the blocked step and ALL remaining PENDING steps
3. Create NEW steps that achieve the same goal using a DIFFERENT approach
4. The new steps must work with what's already been completed
5. Mark new steps as 'Status: PENDING'

Do NOT touch completed steps. Only rewrite from the blocker onward."

            replan_full_result=$(echo "$replan_full_prompt" | claude -p --dangerously-skip-permissions 2>&1)
            echo "$replan_full_result"
            echo -e "${BLUE}Plan rewritten from blocker. Continuing...${NC}"

            retry_count=0
            current_step=""
            continue
        fi

        echo -e "${YELLOW}Retrying with fresh context...${NC}"
        sleep 1
        continue
    fi

    retry_count=$((retry_count + 1))

    if [ $retry_count -ge $MAX_RETRIES ]; then
        echo -e "${RED}Step incomplete after $MAX_RETRIES attempts.${NC}"
        echo -e "${YELLOW}Replanning from this step forward...${NC}"

        # Same replan logic for unclear failures
        replan_full_prompt="A step in IMPLEMENTATION_PLAN.md has failed after $MAX_RETRIES attempts:

BLOCKED STEP: $current_step

Your task:
1. Keep ALL steps marked 'Status: COMPLETE' exactly as they are
2. DELETE the blocked step and ALL remaining PENDING steps
3. Create NEW steps that achieve the same goal using a DIFFERENT approach
4. The new steps must work with what's already been completed
5. Mark new steps as 'Status: PENDING'

Do NOT touch completed steps. Only rewrite from the blocker onward."

        replan_full_result=$(echo "$replan_full_prompt" | claude -p --dangerously-skip-permissions 2>&1)
        echo "$replan_full_result"
        echo -e "${BLUE}Plan rewritten from blocker. Continuing...${NC}"

        retry_count=0
        current_step=""
        continue
    fi

    sleep 1
done
