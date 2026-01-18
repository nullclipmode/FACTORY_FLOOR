# Ownership Gate Agent

Validates repo is safe for autonomous code changes.

## Purpose

Hard stop before Ralph loop runs. No exceptions.

## Checks (ALL must pass)

### 1. CODEOWNERS Exists

```bash
[ -f CODEOWNERS ] || [ -f .github/CODEOWNERS ] || [ -f docs/CODEOWNERS ]
```

FAIL reason: "No CODEOWNERS file found"

### 2. Branch Protection Enabled

```bash
gh api repos/{owner}/{repo}/branches/{default_branch}/protection --silent
```

If 404 or error: FAIL reason: "No branch protection on default branch"

### 3. Reviewer Resolvable

From CODEOWNERS, extract owners for likely changed paths.
At least one must be:
- A valid GitHub user
- A team with members

FAIL reason: "No valid reviewers found in CODEOWNERS"

## Output

```json
{
  "status": "PASS" | "FAIL",
  "checks": {
    "codeowners": true | false,
    "branch_protection": true | false,
    "reviewer_resolvable": true | false
  },
  "fail_reason": null | "string",
  "reviewers": ["user1", "@team/name"]
}
```

## Behavior on FAIL

- Return immediately
- Do NOT proceed to plan generation
- Caller must handle downgrade to manual/claude-fix
