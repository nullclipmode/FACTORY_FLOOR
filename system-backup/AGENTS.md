# Factory Floor Agent Configuration

This configuration references modular rules in `~/.claude/rules/`.

## Active Rules

The following rules are always active for Factory Floor sessions:

- `factory-quality-bar.md` - Production code standards
- `test-first.md` - TDD workflow requirements
- `no-self-assessment.md` - External verification only
- `commit-invariants.md` - All commits must pass gates
- `hitl-triggers.md` - Human review requirements

## Subagents

Ralph uses these native subagents in `~/.claude/agents/`:

- `ralph-planner` - Creates implementation plans (opus model)
- `ralph-builder` - Implements bead tasks (sonnet model)
- `ralph-verifier` - Verifies implementations (sonnet model)
- `ralph-reviewer` - Reviews code changes (sonnet model)

## Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --status in_progress  # Claim work
bd close <id>         # Complete work
bd sync               # Sync with git
```

## Session Completion

When ending a work session:

1. File issues for remaining work
2. Run quality gates (tests, linters, builds)
3. Update issue status
4. **PUSH TO REMOTE** (mandatory):
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # Must show "up to date with origin"
   ```
5. Clean up stashes, prune branches
6. Verify all changes committed AND pushed

**Work is NOT complete until `git push` succeeds.**
