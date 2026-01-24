# Commit Invariants

No uncommitted broken code. Every commit must pass all checks.

## Pre-Commit Requirements

All of these must pass before any commit:

```bash
npm run typecheck  # if present in package.json
npm run lint       # if present
npm run test       # if present
npm run build      # if present
```

## Commit Gate

The commit gate is enforced by `ralph-loop.sh` and cannot be bypassed:
- Agent cannot `--no-verify`
- Agent cannot skip checks
- Agent cannot commit partial work

## Atomic Commits

- One bead = one commit
- Commit message format: `ralph: [bead title] [bead-id]`
- All changes for a bead committed together

## No Bypass Rules

- If commit gate fails → loop back to fix
- If fix attempts exhausted → block bead + add HITL label
- Never commit broken code "to save progress"
- Never push broken commits

## Recovery

If broken code is committed:
1. Revert immediately: `git revert HEAD`
2. Fix the issue
3. Re-run commit gate
4. Commit clean code
