---
description: Fix a bead (issue) using Ralph loop with auto/manual mode
---

# Fix Bead

Fix a bead by generating a plan and executing via Ralph loop.

**Key principle: Tests define "done". No tests = no auto-close.**

## Input

`$ARGUMENTS` should be:
- A bead ID (e.g., `bd-a1b2`)
- `--auto` flag for full automation (default: manual with approval)

If empty, get next ready bead via `bd ready`.

**Task Types:**
- **AUTO**: Has executable acceptance criteria (tests/commands) - can run unattended
- **HITL**: Has `hitl` label - requires human approval, blocks downstream tasks

---

## Mode Detection

Check for mode:
```bash
# Parse arguments
BEAD_ID=""
AUTO_MODE=false

for arg in $ARGUMENTS; do
    if [ "$arg" = "--auto" ]; then
        AUTO_MODE=true
    else
        BEAD_ID="$arg"
    fi
done

# If no bead specified, get next ready one
if [ -z "$BEAD_ID" ]; then
    BEAD_ID=$(bd ready --json | jq -r '.[0].id // empty')
fi
```

---

## Flow

### 1. Fetch Bead

Use Beads CLI to get issue details:
```bash
bd show "$BEAD_ID" --json
```

Extract:
- Title
- Description
- Priority
- Labels
- Dependencies (blockers)
- **Acceptance criteria** (REQUIRED for auto mode)

### 1.5 HITL Gate

**Check if this bead requires human approval:**

```bash
LABELS=$(bd show "$BEAD_ID" --json | jq -r '.labels[]?')

if echo "$LABELS" | grep -q "^hitl$"; then
    echo "═══════════════════════════════════════════════════"
    echo "HITL BEAD: $BEAD_ID"
    echo "═══════════════════════════════════════════════════"
    echo ""
    echo "This bead requires HUMAN approval (taste/judgment)."
    echo "Agent cannot auto-complete HITL tasks."
    echo ""
    echo "To approve: /hitl-approve $BEAD_ID"
    echo "To reject:  bd update $BEAD_ID --status blocked --reason 'needs rework'"
    echo ""
    echo "═══════════════════════════════════════════════════"
    exit 0
fi
```

### 1.6 Dependency Gate

**Check if blocked by incomplete beads:**

```bash
BLOCKERS=$(bd show "$BEAD_ID" --json | jq -r '.blocks[]?' 2>/dev/null)

if [ -n "$BLOCKERS" ]; then
    BLOCKED=false
    BLOCKING_BEADS=""

    for blocker in $BLOCKERS; do
        STATUS=$(bd show "$blocker" --json | jq -r '.status')
        if [ "$STATUS" != "done" ]; then
            BLOCKED=true
            BLOCKING_BEADS="$BLOCKING_BEADS $blocker($STATUS)"
        fi
    done

    if [ "$BLOCKED" = "true" ]; then
        echo "BLOCKED: Waiting on:$BLOCKING_BEADS"
        echo "Complete blocking beads first, or remove dependency."
        exit 1
    fi
fi
```

### 2. Acceptance Criteria Gate (AUTO MODE ONLY)

**For auto mode, acceptance criteria MUST be executable.**

```bash
ACCEPTANCE=$(bd show "$BEAD_ID" --json | jq -r '.acceptance // empty')

if [ "$AUTO_MODE" = "true" ] && [ -z "$ACCEPTANCE" ]; then
    echo "AUTO MODE BLOCKED: No acceptance criteria"
    echo "Add with: bd update $BEAD_ID --acceptance 'tests/e2e/feature.spec.ts'"
    exit 1
fi

# Validate acceptance is executable (test file or command)
if [ "$AUTO_MODE" = "true" ]; then
    # Must be: test file path, test pattern, or shell command
    if ! echo "$ACCEPTANCE" | grep -qE '(\.spec\.|\.test\.|^npm |^pytest |^go test|^curl )'; then
        echo "AUTO MODE BLOCKED: Acceptance criteria not executable"
        echo "Must be test file, test pattern, or verifiable command"
        exit 1
    fi
fi
```

### 3. Ownership Gate

Check repo is safe for automation:

```bash
# Must pass ALL checks
[ -f CODEOWNERS ] || FAIL "No CODEOWNERS file"
gh api repos/{owner}/{repo} --jq '.default_branch_protection' | grep -q 'true' || FAIL "No branch protection"
```

If ANY check fails:
- Output: "OWNERSHIP GATE FAILED: {reason}"
- Do NOT proceed
- Suggest manual fix

### 4. Attempt Tracking

Check bead labels for `ralph-attempts:N`:
```bash
ATTEMPTS=$(bd show "$BEAD_ID" --json | jq -r '.labels[]? | select(startswith("ralph-attempts:")) | split(":")[1] // "0"' | head -1)
ATTEMPTS=${ATTEMPTS:-0}

if [ "$ATTEMPTS" -ge 2 ]; then
    echo "Max attempts reached. Escalating to manual."
    bd label add "$BEAD_ID" needs-human
    exit 1
fi

bd label remove "$BEAD_ID" "ralph-attempts:$ATTEMPTS" 2>/dev/null || true
NEW_ATTEMPTS=$((ATTEMPTS + 1))
bd label add "$BEAD_ID" "ralph-attempts:$NEW_ATTEMPTS"
```

### 5. Manual Approval (if not --auto)

If `AUTO_MODE=false`:
```
═══════════════════════════════════════════════════
FIX-BEAD: $BEAD_ID
═══════════════════════════════════════════════════

BEAD DETAILS:
  Title: {title}
  Priority: {priority}
  Description: {description}
  Acceptance: {acceptance criteria}

READY TO PROCEED?
  Enter 'yes' to generate plan and execute
  Enter 'no' to cancel

═══════════════════════════════════════════════════
```

Wait for explicit approval before continuing.

### 6. Generate Plan (TEST-FIRST)

Create `IMPLEMENTATION_PLAN.md` with:

```markdown
# Implementation Plan: {bead-title}

**Bead ID**: {bead-id}
**Generated**: {timestamp}

## Context
{bead-description}

## Acceptance Criteria (MUST PASS)
{acceptance from bead - these are the tests that define done}

## Steps

### Phase 1: Write Failing Tests
1. Create test file(s) for acceptance criteria
2. Run tests - verify they FAIL (code doesn't exist yet)

### Phase 2: Implement
3. {implementation step}
4. {implementation step}
...

### Phase 3: Verify
N. Run tests - verify they PASS
N+1. Run full test suite - verify no regressions

## Files to Modify
- {file}
```

### 7. Plan Validation

Before executing, validate the plan:
- Are all referenced files real?
- Are the steps grounded in actual repo structure?
- Is scope reasonable for the issue?
- **Does plan include test-first phase?**

If validation FAILS:
- Add `needs-human` label
- Output: "Plan validation failed: {reason}. Needs human review."
- STOP

### 7.5 Lock Test Files (After Phase 1 Complete)

**After test files are created and verified failing, lock them:**

```bash
# Extract test files from Phase 1 of the plan
TEST_FILES=$(grep -oE 'tests?/[^ ]+\.(spec|test)\.(ts|tsx|js|jsx)' IMPLEMENTATION_PLAN.md | sort -u)

# Store list for later unlock
echo "$TEST_FILES" > .locked-test-files

# Make read-only for implementation phase
for f in $TEST_FILES; do
    if [ -f "$f" ]; then
        chmod 444 "$f"
        echo "LOCKED: $f"
    fi
done
```

**If agent attempts to modify locked test files during Phase 2:**
- FAIL immediately
- Add `needs-human` label
- Output: "SECURITY: Agent attempted to modify test files during implementation"
- This is a gaming attempt - escalate to human

### 8. Execute Ralph Loop

```bash
~/.claude/ralph-loop.sh
```

### 8.5 Unlock Test Files (After Ralph Complete)

```bash
# Restore write permissions for completion validation
if [ -f .locked-test-files ]; then
    while IFS= read -r f; do
        chmod 644 "$f" 2>/dev/null || true
    done < .locked-test-files
    rm .locked-test-files
fi
```

### 9. Completion Validation

**After Ralph completes, run acceptance criteria:**

```bash
# Parse acceptance criteria
ACCEPTANCE=$(bd show "$BEAD_ID" --json | jq -r '.acceptance')

# Run each criterion
PASS=true
while IFS= read -r criterion; do
    echo "Running: $criterion"

    if [[ "$criterion" == *.spec.* ]] || [[ "$criterion" == *.test.* ]]; then
        # It's a test file
        npm test -- "$criterion" || PASS=false
    else
        # It's a command
        eval "$criterion" || PASS=false
    fi
done <<< "$ACCEPTANCE"

if [ "$PASS" = "false" ]; then
    echo "COMPLETION VALIDATION FAILED"
    echo "Acceptance criteria not satisfied"
    # Increment attempts, don't close
    exit 1
fi
```

### 10. Create PR

After Ralph completes AND acceptance passes:
- Create branch: `fix/{bead-id}`
- Commit changes
- Create PR with:
  - Title: `fix: {bead-title}`
  - Body: Links to bead ID + acceptance criteria results
  - Labels: `auto-generated`

### 11. Update Bead

```bash
# Mark as in_progress during work
bd update "$BEAD_ID" --status in_progress

# After PR created, add note
bd comments add "$BEAD_ID" "PR created: {pr_url}"

# ONLY close if acceptance criteria passed
if [ "$PASS" = "true" ]; then
    bd close "$BEAD_ID" --reason "Fixed via {pr_url} - all acceptance criteria passed"
fi
```

---

## Output Format

```
═══════════════════════════════════════════════════
FIX-BEAD: {bead-id}
═══════════════════════════════════════════════════

MODE: {AUTO | MANUAL}
STATUS: {RUNNING | COMPLETED | FAILED}

GATES:
  Acceptance Criteria: {PRESENT | MISSING}
  Ownership: {PASS | FAIL}
  Attempts: {N}/2
  Plan Valid: {PASS | FAIL}
  Test Lock: {ACTIVE | RELEASED | VIOLATED}
  Completion Valid: {PASS | FAIL | PENDING}

ACCEPTANCE RESULTS:
  ✓ tests/e2e/login.spec.ts (5 passed)
  ✓ tests/unit/auth.test.ts (3 passed)

RESULT:
  PR: {url}
  Bead: {closed | in_progress | needs-human}

═══════════════════════════════════════════════════
```

---

## Error Handling

| Error | Action |
|-------|--------|
| Bead not found | Prompt for valid ID |
| **HITL bead** | **Stop, surface for human approval** |
| **Blocked by incomplete bead** | **Stop, list blockers** |
| No acceptance criteria (auto mode) | Block, require criteria |
| Non-executable criteria (auto mode) | Block, explain format |
| Ownership gate fail | Stop, output reason |
| Max attempts | Add needs-human label, stop |
| Plan validation fail | Add needs-human label, stop |
| **Test file modification attempt** | **SECURITY FAIL, needs-human, stop** |
| Ralph loop fail | Increment attempts, stop |
| **Acceptance tests fail** | **Increment attempts, don't close** |
| PR creation fail | Output error, keep changes |

---

## Usage Examples

```bash
# Manual mode (default) - requires approval
/fix-bead bd-a1b2

# Auto mode - requires executable acceptance criteria
/fix-bead bd-a1b2 --auto

# Get next ready bead (manual mode)
/fix-bead

# Get next ready bead (auto mode)
/fix-bead --auto
```

## Creating Beads for Auto-Fix

```bash
# Good - executable acceptance criteria
bd create "Add login endpoint" \
  --acceptance "tests/e2e/login.spec.ts"

# Good - multiple criteria
bd create "Add user auth" \
  --acceptance "tests/e2e/login.spec.ts
tests/e2e/logout.spec.ts
tests/unit/auth.test.ts"

# Good - command-based
bd create "Fix health endpoint" \
  --acceptance "curl -sf http://localhost:3000/api/health"

# Bad - won't work in auto mode
bd create "Add login endpoint"  # No acceptance criteria

# Bad - won't work in auto mode
bd create "Add login endpoint" \
  --acceptance "login should work"  # Not executable
```

## HITL (Human-in-the-Loop) Workflow

For tasks requiring human judgment (UI review, copy approval, taste decisions):

```bash
# Create HITL bead - no acceptance criteria, has hitl label
bd create "Review login page design" --label hitl

# Create AUTO bead that depends on HITL approval
bd create "Wire login to API" \
  --acceptance "tests/e2e/login.spec.ts" \
  --blocks "ff-abc"  # ff-abc is the HITL bead

# Workflow:
# 1. Agent runs through AUTO beads
# 2. Hits HITL bead → pauses, surfaces for human
# 3. Human reviews, approves with /hitl-approve ff-abc
# 4. Agent continues with downstream AUTO beads
```

**Dependency Graph Example:**

```
ff-001 (AUTO) Build API endpoint
    ↓
ff-002 (AUTO) Add database migration
    ↓
ff-003 (HITL) Review UI design ← PAUSE HERE
    ↓
ff-004 (AUTO) Wire UI to API
    ↓
ff-005 (AUTO) Add E2E tests
```

Agent completes ff-001, ff-002 automatically.
Pauses at ff-003, waits for human.
After `/hitl-approve ff-003`, continues with ff-004, ff-005.
