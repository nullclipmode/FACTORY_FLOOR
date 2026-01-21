# Factory Floor

## WHAT
Personal app factory. Build web/mobile apps from plain language + reference images.

**Structure:**
- `infra/` - Terraform (GCP Cloud Run, Load Balancer, Cloud Armor)
- `.beads/` - Git-backed issue tracker (issues.jsonl)
- `.claude/commands/` - Custom slash commands

**Stack:**
- Frontend: Vercel
- Backend: GCP Cloud Run
- Database: Supabase (Postgres + Auth)
- Files: GCS

## WHY
Autonomous operation:
- Complete full tasks without unnecessary questions
- When blocked: create bead with details, mark HITL, await human input
- HITL only when human judgment genuinely required
- Each app has its own CLAUDE.md with app-specific context

## HOW

### Beads (Issue Tracking)
```bash
bd create "title"    # Create issue
bd list              # Show open
bd close <id>        # Complete
```
Issues live in `.beads/issues.jsonl`. Check before creating duplicates.

### Test-First Principle
Write tests before implementation. Test files locked—cannot be modified to pass. Completion validated against original tests. Enforcement in `~/.claude/ralph-loop.sh`.

### HITL Tasks
Some beads require human judgment (design approval, ambiguous specs). Check `status: hitl` before auto-proceeding.

### Verification
```bash
npm run build        # Must pass
npm run test         # Must pass
```
Run both before marking work complete.

### Sandbox (AFK Mode)
When running unattended via `~/.claude/ralph-sandbox.sh`:
- Only app directory mounted at /workspace
- No host filesystem access outside workspace
- Git via HTTPS/.netrc (no SSH)
- If task needs unavailable credentials, mark bead `hitl`
