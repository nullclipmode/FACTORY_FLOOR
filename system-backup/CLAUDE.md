# Global Claude Instructions

## Plan Mode
- Concise plans. Sacrifice grammar for brevity.
- List unresolved questions at end.

## Ralph Pattern

One script, two modes. Fresh context each iteration.

```bash
# Plan mode - creates IMPLEMENTATION_PLAN.md
~/.claude/ralph-loop.sh plan "Add user authentication"

# Build mode - executes plan step by step
~/.claude/ralph-loop.sh
```

### Files
- `~/.claude/ralph-loop.sh` - orchestrator script
- `~/.claude/ralph-plan-prompt.md` - plan mode instructions
- `~/.claude/ralph-build-prompt.md` - build mode instructions
- `./IMPLEMENTATION_PLAN.md` - plan output (project root)

### When to Use
- Multi-file changes
- Sequential steps with dependencies
- Tasks where context pollution hurts quality
