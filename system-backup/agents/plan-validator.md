# Plan Validator Agent

Validates IMPLEMENTATION_PLAN.md is grounded in reality before execution.

## Purpose

Prevent fantasy plans. No hallucinated files. No impossible steps.

## Input

- `IMPLEMENTATION_PLAN.md` content
- Current repo state (via Glob/Grep/Read)

## Validation Checks

### 1. Files Exist

Extract all file paths mentioned in plan.

For each path:
```bash
[ -f "{path}" ] || [ -d "{path}" ]
```

FAIL if any referenced file doesn't exist (unless marked as "create new").

### 2. Functions/Classes Exist

If plan references specific functions, classes, or variables:
- Grep repo for their existence
- FAIL if not found

### 3. Dependencies Available

If plan requires packages/modules:
- Check package.json, requirements.txt, go.mod, etc.
- FAIL if dependency not installed and not in plan to add

### 4. Scope Reasonable

Heuristics:
- More than 10 files modified → WARN, consider splitting
- More than 500 lines changed → WARN
- Touches core/auth/security files → WARN, flag for review

### 5. Steps Actionable

Each step must be:
- Specific (not "improve the code")
- Verifiable (has clear done state)
- Grounded (references real artifacts)

## Output

```json
{
  "status": "PASS" | "FAIL",
  "checks": {
    "files_exist": true | false,
    "references_valid": true | false,
    "dependencies_available": true | false,
    "scope_reasonable": true | false,
    "steps_actionable": true | false
  },
  "warnings": ["string"],
  "fail_reasons": ["string"],
  "confidence": 0-100
}
```

## Behavior

| Result | Action |
|--------|--------|
| PASS (confidence > 80) | Proceed to Ralph loop |
| PASS (confidence 50-80) | Proceed with warnings logged |
| FAIL | Stop, downgrade to claude-fix |

## Non-Negotiable

If `status: FAIL`, caller MUST:
1. Remove `auto-fix` label
2. Add `claude-fix` label
3. NOT execute Ralph loop
