# Ralph / Factory Floor System Specification

Version: 3.0
Updated: 2026-01-24

## 1. System Intent

Autonomous software development with human oversight at decision points.

**Core principle**: Agent builds, human approves ambiguous decisions.

## 2. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ralph-loop.sh                            │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐     │
│  │  PLAN   │ → │  BUILD  │ → │ VERIFY  │ → │ REVIEW  │ → ✓ │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘     │
│       ↓             ↓             ↓             ↓           │
│  ralph-      ralph-        ralph-        ralph-             │
│  planner     builder       verifier      reviewer           │
│  (subagent)  (subagent)    (subagent)    (subagent)         │
└─────────────────────────────────────────────────────────────┘
        ↓
   ┌─────────┐
   │ BEADS   │  .beads/issues.jsonl
   └─────────┘
```

### 2.1 Native Subagents

Ralph now uses Claude Code native subagents for isolated context windows:

| Subagent | Model | Purpose |
|----------|-------|---------|
| ralph-planner | opus | Creates implementation plans with test-first phases |
| ralph-builder | sonnet | Implements bead acceptance criteria |
| ralph-verifier | sonnet | Verifies implementations pass build/test/visual checks |
| ralph-reviewer | sonnet | Reviews git diff for bugs, security, missed requirements |

Subagents are defined in `~/.claude/agents/` with YAML frontmatter.

## 3. Execution Flow

### 3.1 Plan Mode
```bash
ralph-loop.sh plan "task description"
```
1. Load `ralph-plan-prompt.md`
2. Explore codebase for context
3. Generate `IMPLEMENTATION_PLAN.md`
4. Convert plan to beads via `plan-to-beads.sh`

### 3.2 Build Mode
```bash
ralph-loop.sh
```
1. Get next runnable bead (`bd ready --label ralph`)
2. If HITL bead → exit 2, show `bd prime`
3. Execute build with `ralph-build-prompt.md`
4. On `<promise>DONE</promise>` → verify phase
5. On `<promise>FAILED</promise>` → retry or block

### 3.3 Verify Phase
1. Run build/test commands
2. Start app, check visual/functional
3. Output structured result (see Section 7.1)

### 3.4 Review Phase
1. Get git diff
2. Check for bugs, security, missed requirements
3. Output `<review>APPROVED</review>` or `<review>NEEDS_WORK</review>`

### 3.5 Commit Gate
Enforced checks before any commit:
```bash
npm run typecheck  # if present
npm run lint       # if present
npm run test       # if present
npm run build      # if present
```
All must pass. No bypass.

## 4. State Model

### 4.1 Bead Structure
```json
{
  "id": "ff-xxx",
  "title": "string",
  "description": "string",
  "status": "open | in_progress | blocked | closed",
  "labels": ["ralph", "hitl", "auto-fix"],
  "acceptance": "observable criterion",
  "deps": ["blocks:ff-yyy"],
  "comments": []
}
```

### 4.2 Comment Format (Audit Trail)
All failure comments follow this structure:
```
[BEAD_ID] [TIMESTAMP] [PHASE] Message.
[Structured details]
```

Where:
- **BEAD_ID**: The bead identifier (e.g., `ff-1j6`)
- **TIMESTAMP**: ISO 8601 UTC (e.g., `2026-01-22T14:32:00Z`)
- **PHASE**: `BUILD`, `VERIFY`, or `REVIEW`

Example:
```
[ff-1j6] [2026-01-22T14:32:00Z] [VERIFY] Failed after 5 attempts.
<verify>FAIL:FUNCTIONAL</verify>
Acceptance: #2 ("API returns 401 for unauthenticated requests")
Error: Got 500 instead of 401
Details: auth middleware throws instead of returning status
Fix direction: Catch exception in middleware
Confidence: HIGH
```

### 4.3 Bead Lifecycle
```
open → in_progress → closed
         ↓
      blocked (+ hitl label if needs human)
```

## 5. Control Loop Limits

| Constant | Default | Description |
|----------|---------|-------------|
| MAX_ITERATIONS | 50 | Total loop iterations before hard stop |
| MAX_BEAD_ATTEMPTS | 3 | Full build→verify→review cycles per bead |
| MAX_RETRIES | 10 | Retries within a single phase |
| VERIFY_RETRIES | 5 | Verification attempts before loop-back |
| REVIEW_RETRIES | 3 | Code review attempts before warning |

### 5.1 Attempt Counting (Option B)
```bash
# Check BEFORE incrementing to prevent off-by-one
if [ "$bead_total_attempts" -ge "$MAX_BEAD_ATTEMPTS" ]; then
    # fail
fi
bead_total_attempts=$((bead_total_attempts + 1))
```

## 6. HITL Triggers

Agent pauses and exits with code 2 when:
1. Bead has `hitl` label
2. Verify outputs `<verify>HITL</verify>`
3. Bead fails MAX_BEAD_ATTEMPTS cycles
4. Visual/design decisions needed
5. Security-sensitive changes
6. Ambiguous requirements

Resume: `/hitl-approve <bead_id>`

## 7. Output Formats

### 7.1 Verification Output

**Pass:**
```
<verify>PASS</verify>
```

**Fail:**
```
<verify>FAIL:CATEGORY</verify>
Acceptance: #N ("[criterion text]")
Error: [what actually happened]
Details: [specific location/message]
Fix direction: [what to change]
Confidence: HIGH | MEDIUM | LOW
```

**HITL Required:**
```
<verify>HITL</verify>
Needs human review:
- [Step N]: [what to review]
- [Step M]: [what to review]
```

### 7.2 Verification Categories
- `BUILD` - Compilation/bundling failed
- `STARTUP` - App won't start
- `VISUAL` - UI doesn't render correctly
- `FUNCTIONAL` - Behavior doesn't match acceptance
- `TEST` - Test suite failures

### 7.3 Confidence Levels
- **HIGH** - Deterministic failure, fix direction clear (compiler error, missing file)
- **MEDIUM** - Likely cause identified, fix may vary (flaky test, race condition)
- **LOW** - Unclear root cause, may need HITL (intermittent, environment-specific)

### 7.4 Review Output

**Approved:**
```
<review>APPROVED</review>
```

**Needs Work:**
```
<review>NEEDS_WORK</review>
Issues:
1. [file:line] - [description of issue]
2. [file:line] - [description of issue]
Fix: [brief suggestion]
```

### 7.5 Build Output

**Complete:**
```
<promise>DONE</promise>
```

**Failed:**
```
<promise>FAILED</promise>
```

## 8. Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | All beads complete | Success |
| 1 | Error (no beads, max iterations) | Check logs |
| 2 | Needs human input | Run `bd prime`, then `/hitl-approve` |

## 9. Invariants

1. Every bead has observable acceptance criteria
2. Tests written before implementation (test-first)
3. Commit gate always enforced - no bypass
4. HITL beads never auto-closed
5. Comments capture failure context with structured format
6. Closed beads are immutable

## 10. Failure Modes

| Failure | Detection | Recovery |
|---------|-----------|----------|
| Build won't compile | Commit gate | Loop back, retry |
| Tests fail | Commit gate | Loop back, fix |
| Verify times out | VERIFY_RETRIES exhausted | Comment added, loop back |
| Bead stuck | MAX_BEAD_ATTEMPTS reached | Block + hitl, exit 2 |
| Runaway loop | MAX_ITERATIONS reached | Hard stop, exit 1 |

## 11. File Locations

### Live (executed)
```
~/.claude/ralph-loop.sh           # Main orchestrator
~/.claude/plan-to-beads.sh        # Plan to bead converter
~/.claude/AGENTS.md               # Agent configuration reference

# Subagents (native Claude Code subagents)
~/.claude/agents/ralph-planner.md
~/.claude/agents/ralph-builder.md
~/.claude/agents/ralph-verifier.md
~/.claude/agents/ralph-reviewer.md

# Modular rules (always active)
~/.claude/rules/factory-quality-bar.md
~/.claude/rules/test-first.md
~/.claude/rules/no-self-assessment.md
~/.claude/rules/commit-invariants.md
~/.claude/rules/hitl-triggers.md

# Skills (workflow definitions)
~/.claude/skills/tdd-workflow/SKILL.md
~/.claude/skills/codemap-updater/SKILL.md
~/.claude/skills/refactor-clean/SKILL.md

# Hooks
~/.claude/settings.json           # Hook configuration
~/.claude/stop-hook-git-check.sh  # Git status check on stop

# Legacy prompts (kept for reference)
~/.claude/ralph-plan-prompt.md
~/.claude/ralph-build-prompt.md
~/.claude/ralph-verify-prompt.md
~/.claude/ralph-review-prompt.md
```

### Backup (version controlled)
```
system-backup/ralph/              # Ralph loop script
system-backup/agents/             # Subagent definitions
system-backup/rules/              # Modular rules
system-backup/skills/             # Skill definitions
system-backup/scripts/            # Utility scripts
system-backup/settings.json       # Hook configuration
```

### Per-Project
```
./IMPLEMENTATION_PLAN.md
./CLAUDE.md
./AGENTS.md (copied from ~/.claude/)
./.beads/issues.jsonl
```

## 12. Command Reference

```bash
# Ralph
ralph-loop.sh plan "task"    # Create plan + beads
ralph-loop.sh                # Execute beads

# Beads
bd create "title"            # New bead
bd list                      # Show open
bd list --label ralph        # Filter by label
bd ready                     # Next runnable
bd prime                     # Current state summary
bd close <id>                # Complete
bd update <id> --status X    # Change status
bd label add <id> hitl       # Add label
bd comments add <id> "msg"   # Add comment

# HITL
/hitl-approve <bead_id>      # Resume after human review
```

## 13. Quality Bar

Defined in modular rules at `~/.claude/rules/`:

### factory-quality-bar.md
- Resolve all TODOs before commit
- Code compiles
- Lint/test/build pass (when present)
- Behavior changes include test adds/updates
- No silent error swallowing

### test-first.md
- Write failing tests before implementation
- Test files are read-only after Phase 1
- Cannot modify tests to make them pass

### no-self-assessment.md
- Agent cannot mark DONE without external verification
- Commit gate is the completion oracle

### commit-invariants.md
- All checks must pass before commit
- No broken code committed
- Atomic commits per bead

### hitl-triggers.md
- Visual/design decisions need human review
- Security-sensitive changes need review
- Ambiguous requirements escalate to HITL

## 14. Hooks Configuration

Defined in `~/.claude/settings.json`:

### PreToolUse Hooks
- **git push**: Run full commit gate before push

### PostToolUse Hooks
- **Edit/Write .ts/.tsx/.js/.jsx/.json/.css/.md**: Auto-format with prettier
- **Edit/Write .ts/.tsx**: Run tsc --noEmit for type feedback
- **Edit/Write .ts/.tsx/.js/.jsx**: Warn if console.log detected

### Stop Hooks
- **Git check**: Ensure all changes committed and pushed
- **Console.log audit**: Warn about debug logs in recent changes
