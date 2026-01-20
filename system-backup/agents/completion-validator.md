# Completion Validator Agent

Validates task completion by running executable acceptance criteria.

## Purpose

**The only way to auto-close a bead is if tests prove it's done.**

No tests = no auto-close.

## Input

- Bead ID
- Bead acceptance criteria (from `bd show <id> --json`)
- Current repo state

## Validation Flow

### 1. Parse Acceptance Criteria

```bash
bd show <bead-id> --json | jq -r '.acceptance'
```

Acceptance must be one of:
- **Test file path**: `tests/e2e/login.spec.ts`
- **Test pattern**: `npm test -- --grep "login"`
- **Executable command**: `curl -f http://localhost:3000/api/health`
- **Multiple criteria** (newline separated)

### 2. Reject Non-Executable Criteria

If acceptance is:
- Empty → FAIL
- Vague text ("it works", "feature complete") → FAIL
- No test file and no command → FAIL

```json
{
  "status": "FAIL",
  "reason": "Acceptance criteria not executable. Must be test file or command."
}
```

### 3. Run Acceptance Tests

For each criterion:

**If test file:**
```bash
# Detect test runner
if [ -f "package.json" ]; then
  npm test -- {test-file}
elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ]; then
  pytest {test-file}
elif [ -f "go.mod" ]; then
  go test -run {pattern}
fi
```

**If command:**
```bash
eval "{command}"
# Check exit code
```

### 4. Collect Results

```json
{
  "status": "PASS" | "FAIL",
  "criteria_results": [
    {
      "criterion": "tests/e2e/login.spec.ts",
      "passed": true,
      "output": "5 passed"
    },
    {
      "criterion": "curl -f /api/health returns 200",
      "passed": true,
      "output": "HTTP 200"
    }
  ],
  "summary": "2/2 acceptance criteria passed"
}
```

## Decision Matrix

| All Tests Pass | Build Passes | Action |
|----------------|--------------|--------|
| Yes | Yes | Auto-close bead, merge PR |
| Yes | No | Fix build, retry |
| No | Yes | Code incomplete, retry or escalate |
| No | No | Major issues, escalate |

## Integration with fix-bead

```bash
# In /fix-bead flow:

# After Ralph loop completes:
completion_result=$(completion-validator $BEAD_ID)

if [ "$completion_result" = "PASS" ]; then
  bd close $BEAD_ID --reason "All acceptance criteria passed"
  gh pr merge --auto
else
  # Increment attempt counter
  # If max attempts, add needs-human label
fi
```

## Escape Hatch

For truly non-testable tasks, human can:
```bash
bd close <id> --force --reason "Manual verification: <explanation>"
```

This bypasses the validator but leaves an audit trail.

## Output

```
═══════════════════════════════════════════════════
COMPLETION VALIDATOR: ff-abc
═══════════════════════════════════════════════════

ACCEPTANCE CRITERIA:
  1. tests/e2e/login.spec.ts
  2. tests/unit/auth.test.ts

RESULTS:
  1. ✓ PASS (5 tests passed)
  2. ✓ PASS (3 tests passed)

VERDICT: PASS - All criteria satisfied
ACTION: Closing bead, merging PR

═══════════════════════════════════════════════════
```
