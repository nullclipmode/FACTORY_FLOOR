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
- Dependencies
- **Acceptance criteria** (REQUIRED for auto mode)

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

### 8. Execute Ralph Loop

```bash
~/.claude/ralph-loop.sh
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
| No acceptance criteria (auto mode) | Block, require criteria |
| Non-executable criteria (auto mode) | Block, explain format |
| Ownership gate fail | Stop, output reason |
| Max attempts | Add needs-human label, stop |
| Plan validation fail | Add needs-human label, stop |
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
