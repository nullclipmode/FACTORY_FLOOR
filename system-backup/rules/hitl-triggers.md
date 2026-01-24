# HITL Triggers

When to pause and request Human-In-The-Loop review.

## Automatic HITL Triggers

Agent pauses and exits with code 2 when:

1. **Explicit HITL label** - Bead has `hitl` label
2. **Verification requests it** - Verifier outputs `<verify>HITL</verify>`
3. **Max attempts exhausted** - Bead fails MAX_BEAD_ATTEMPTS cycles
4. **Low confidence** - Verification confidence is LOW

## Situational HITL Triggers

Request HITL for:

### Visual/Design Decisions
- Color choices, layouts, spacing
- Animation timing
- "Does this look right?"

### Security-Sensitive Changes
- Authentication/authorization changes
- API key handling
- User data processing
- Permission changes

### Ambiguous Requirements
- Conflicting acceptance criteria
- Missing information
- Multiple valid interpretations

### Risky Operations
- Database migrations in production
- Irreversible data changes
- External service integrations

## HITL Workflow

1. Agent marks bead with `hitl` label
2. Agent adds comment explaining what needs review
3. Agent exits with code 2
4. Human reviews and decides
5. Human runs `/hitl-approve <bead_id>` to continue

## Resume After HITL

```bash
/hitl-approve <bead_id>  # Remove hitl label, continue loop
```

Or manually:
```bash
bd label remove <bead_id> hitl
bd update <bead_id> --status in_progress
./ralph-loop.sh
```
