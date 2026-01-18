---
description: Fix a Linear issue using Ralph loop
---

# Fix Issue

Fix a Linear issue by generating a plan and executing via Ralph loop.

## Input

`$ARGUMENTS` should be a Linear issue identifier (e.g., `PROJ-123` or issue URL).

If empty, prompt user for issue ID.

---

## Flow

### 1. Fetch Issue

Use Linear plugin to get issue details:
- Title
- Description
- Labels
- Attachments
- Comments

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

Check Linear labels for `ralph-attempts:N`:
- If N >= 2: Output "Max attempts reached. Escalating to claude-fix." and STOP
- If N < 2: Increment counter (add label `ralph-attempts:{N+1}`)

### 4. Generate Plan

Create `IMPLEMENTATION_PLAN.md` with:

```markdown
# Implementation Plan: {issue-title}

**Linear Issue**: {issue-id}
**Generated**: {timestamp}

## Context
{issue-description}

## Steps
1. {step}
2. {step}
...

## Acceptance Criteria
- [ ] {criteria from issue}

## Files to Modify
- {file}
```

### 5. Plan Validation

Before executing, validate the plan:
- Are all referenced files real?
- Are the steps grounded in actual repo structure?
- Is scope reasonable for the issue?

If validation FAILS:
- Remove `auto-fix` label
- Add `claude-fix` label
- Output: "Plan validation failed: {reason}. Downgraded to claude-fix."
- STOP

### 6. Execute Ralph Loop

```bash
~/.claude/ralph-loop.sh
```

### 7. Create PR

After Ralph completes:
- Create branch: `fix/{issue-id}`
- Commit changes
- Create PR with:
  - Title: `fix: {issue-title}`
  - Body: Links to Linear issue
  - Labels: `auto-generated`

### 8. Update Linear

- Link PR to issue
- Move issue to "In Review" status
- Add comment with PR link

---

## Output Format

```
═══════════════════════════════════════════════════
FIX-ISSUE: {issue-id}
═══════════════════════════════════════════════════

STATUS: {RUNNING | COMPLETED | FAILED}

GATES:
  Ownership: {PASS | FAIL}
  Attempts: {N}/2
  Plan Valid: {PASS | FAIL}

RESULT:
  PR: {url}
  Issue: {moved to In Review | unchanged}

═══════════════════════════════════════════════════
```

---

## Error Handling

| Error | Action |
|-------|--------|
| Issue not found | Prompt for valid ID |
| Ownership gate fail | Stop, output reason |
| Max attempts | Escalate to claude-fix |
| Plan validation fail | Downgrade to claude-fix |
| Ralph loop fail | Increment attempts, stop |
| PR creation fail | Output error, keep changes |
