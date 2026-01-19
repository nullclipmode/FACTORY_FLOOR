---
description: Fix a bead (issue) using Ralph loop with auto/manual mode
---

# Fix Bead

Fix a bead by generating a plan and executing via Ralph loop.

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
- Acceptance criteria

### 2. Ownership Gate

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

### 3. Attempt Tracking

Check bead labels for `ralph-attempts:N`:
```bash
# Get current attempt count from labels
ATTEMPTS=$(bd show "$BEAD_ID" --json | jq -r '.labels[]? | select(startswith("ralph-attempts:")) | split(":")[1] // "0"' | head -1)
ATTEMPTS=${ATTEMPTS:-0}

if [ "$ATTEMPTS" -ge 2 ]; then
    echo "Max attempts reached. Escalating to manual."
    bd label add "$BEAD_ID" needs-human
    exit 1
fi

# Increment counter
bd label remove "$BEAD_ID" "ralph-attempts:$ATTEMPTS" 2>/dev/null || true
NEW_ATTEMPTS=$((ATTEMPTS + 1))
bd label add "$BEAD_ID" "ralph-attempts:$NEW_ATTEMPTS"
```

### 4. Manual Approval (if not --auto)

If `AUTO_MODE=false`:
```
═══════════════════════════════════════════════════
FIX-BEAD: $BEAD_ID
═══════════════════════════════════════════════════

BEAD DETAILS:
  Title: {title}
  Priority: {priority}
  Description: {description}

READY TO PROCEED?
  Enter 'yes' to generate plan and execute
  Enter 'no' to cancel

═══════════════════════════════════════════════════
```

Wait for explicit approval before continuing.

### 5. Generate Plan

Create `IMPLEMENTATION_PLAN.md` with:

```markdown
# Implementation Plan: {bead-title}

**Bead ID**: {bead-id}
**Generated**: {timestamp}

## Context
{bead-description}

## Steps
1. {step}
2. {step}
...

## Acceptance Criteria
- [ ] {criteria from bead}

## Files to Modify
- {file}
```

### 6. Plan Validation

Before executing, validate the plan:
- Are all referenced files real?
- Are the steps grounded in actual repo structure?
- Is scope reasonable for the issue?

If validation FAILS:
- Add `needs-human` label
- Output: "Plan validation failed: {reason}. Needs human review."
- STOP

### 7. Execute Ralph Loop

```bash
~/.claude/ralph-loop.sh
```

### 8. Create PR

After Ralph completes:
- Create branch: `fix/{bead-id}`
- Commit changes
- Create PR with:
  - Title: `fix: {bead-title}`
  - Body: Links to bead ID
  - Labels: `auto-generated`

### 9. Update Bead

```bash
# Mark as in_progress during work
bd update "$BEAD_ID" --status in_progress

# After PR created, add note
bd comments add "$BEAD_ID" "PR created: {pr_url}"

# If PR merged, close bead
bd close "$BEAD_ID" --reason "Fixed via {pr_url}"
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
  Ownership: {PASS | FAIL}
  Attempts: {N}/2
  Plan Valid: {PASS | FAIL}

RESULT:
  PR: {url}
  Bead: {closed | in_progress}

═══════════════════════════════════════════════════
```

---

## Error Handling

| Error | Action |
|-------|--------|
| Bead not found | Prompt for valid ID |
| Ownership gate fail | Stop, output reason |
| Max attempts | Add needs-human label, stop |
| Plan validation fail | Add needs-human label, stop |
| Ralph loop fail | Increment attempts, stop |
| PR creation fail | Output error, keep changes |

---

## Usage Examples

```bash
# Manual mode (default) - requires approval
/fix-bead bd-a1b2

# Auto mode - full automation
/fix-bead bd-a1b2 --auto

# Get next ready bead (manual mode)
/fix-bead

# Get next ready bead (auto mode)
/fix-bead --auto
```
