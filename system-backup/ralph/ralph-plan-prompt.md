# Ralph Plan Mode

Break task into atomic, test-first steps.

## Process
1. Read TASK
2. Explore codebase for context
3. Check ~/.claude/skills/ for relevant patterns
4. Create IMPLEMENTATION_PLAN.md (format below)
5. Update CLAUDE.md with stack/structure/commands

## IMPLEMENTATION_PLAN.md Format

```markdown
# Implementation Plan
Task: [from input]
Created: [timestamp]
Status: IN_PROGRESS
Acceptance: [test file(s) or command(s) that prove done]

## Phase 1: Failing Tests

Step 1: Create test file(s)
- Task: Write tests covering requirements
- Done: Test files exist
- Status: PENDING

Step 2: Verify tests fail
- Task: Run tests before implementation
- Done: Tests fail as expected
- Status: PENDING

## Phase 2: Implement

Step 3: [name]
- Task: [specific action]
- Done: [observable result]
- Review: AUTO | HITL
- Status: PENDING

## Phase 3: Verify

Step N: Run acceptance tests
- Task: Execute acceptance test suite
- Done: All tests pass
- Status: PENDING

Step N+1: Run full suite
- Task: Execute full test suite
- Done: No regressions
- Status: PENDING
```

## Rules
1. Test-first mandatory - Phase 1 writes tests before implementation
2. Each step = one atomic action
3. Order highest-risk first: infra/auth/data → deps → leaves
4. Be explicit - vague steps fail
5. Done criteria must be observable (command or file check)
6. Mark `Review: HITL` for steps requiring human judgment (see below)

## Acceptance Criteria Guide

Observable outcomes, not implementation details.

| Type | Done Criteria | Verify |
|------|---------------|--------|
| New file | File exists with exports | `[ -f src/foo.ts ]` |
| New function | Function callable | `grep -q "export function"` |
| UI component | Renders without error | `npm run build` |
| API endpoint | Returns expected | `curl localhost:3000/api/x` |
| Bug fix | Repro fails | Test passes |
| Refactor | Behavior unchanged | Existing tests pass |
| Style/UX | Matches intent | HITL (human review) |

## Review Types

**AUTO** (default): Agent completes without pause. Use for:
- Deterministic tasks (create file, run command, fix type error)
- Tasks with objective pass/fail criteria
- Test execution

**HITL** (Human-in-the-Loop): Agent pauses for human approval. Use for:
- Visual/design review ("Does this look right?")
- Copy/tone decisions ("Is this wording correct?")
- Ambiguous requirements needing clarification
- Security-sensitive changes (auth, permissions, credentials)
- Destructive operations (delete, migration, prod deploy)

When a step is marked HITL, the agent will:
1. Complete the work
2. Create/update bead with `hitl` label
3. Pause and surface for human review
4. Resume only after `/hitl-approve`

## CLAUDE.md Generation

For new apps, create `./CLAUDE.md` from `templates/CLAUDE.md.template`:
- Stack: framework/styling decisions
- Structure: directories created
- Commands: project scripts
- Max 30 lines. Only diffs from Factory Floor defaults.

Now read the TASK and create the plan.
