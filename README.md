# Factory Floor

Personal app factory for building web/mobile apps from plain language and reference images. Designed for autonomous AI operation.

## Quick Start

```bash
# Create a new app
/new-app my-cool-app

# Clone a design from screenshot
/clone-design references/homepage.png

# Fix an issue
/fix-bead ff-abc
```

## Documentation

| Document | Purpose |
|----------|---------|
| [HANDOFF.md](HANDOFF.md) | Complete system reference |
| [CHEAT_SHEET.md](CHEAT_SHEET.md) | Command quick reference |
| [DISASTER_RECOVERY.md](DISASTER_RECOVERY.md) | Setup from scratch |
| [CLAUDE.md](CLAUDE.md) | AI instructions |

## Architecture

```
Frontend: Vercel
Backend: GCP Cloud Run
Database: Supabase (Postgres + Auth)
Files: Google Cloud Storage
Security: Cloud Armor (WAF, rate limiting)
IaC: Terraform
```

## Key Systems

### Beads (Issue Tracking)
Git-native, AI-optimized issue tracker.

```bash
bd create "Add login"    # Create issue
bd list                  # Show all
bd ready                 # Show unblocked
bd close ff-abc          # Complete
```

### Ralph Loop (Complex Tasks)
Two-mode workflow for multi-step tasks.

```bash
~/.claude/ralph-loop.sh plan "Add auth"   # Plan mode
~/.claude/ralph-loop.sh                   # Build mode
```

### AFK Mode (Docker Sandbox)
Run Ralph unattended in isolated container.

**Setup:**
```bash
cd ~/.claude
docker build -t claude-ralph:latest -f Dockerfile.ralph .
```

**Run:**
```bash
export GITHUB_TOKEN="your-token"
export ANTHROPIC_API_KEY="your-key"
~/.claude/ralph-sandbox.sh /path/to/app
```

**Security:**
- Read-only container
- 4GB memory, 2 CPUs
- No host filesystem access outside /workspace
- Git via HTTPS (no SSH keys)
- All capabilities dropped

### Maintenance Runner
Process lint/typecheck/test beads with Haiku.

```bash
~/.claude/ralph-maintenance.sh              # All maintenance beads
~/.claude/ralph-maintenance.sh class:lint   # Lint only
```

**Bead classes:**
| Class | Processor |
|-------|-----------|
| `class:lint` | ralph-maintenance.sh (Haiku) |
| `class:typecheck` | ralph-maintenance.sh (Haiku) |
| `class:test` | ralph-maintenance.sh (Haiku) |
| `class:feature` | ralph-loop.sh (Opus) |

### Test-First Validation
- Tests written before implementation
- Test files locked (cannot be modified to pass)
- Build + tests must pass before completion

## Directory Structure

```
FACTORY_FLOOR/
├── CLAUDE.md              # AI instructions
├── infra/                 # Terraform (GCP)
├── .beads/                # Issue tracker
├── templates/             # Scaffolding
│   └── CLAUDE.md.template
└── system-backup/         # Claude config backup
```

## Slash Commands

| Command | Purpose |
|---------|---------|
| `/new-app` | Create new project |
| `/clone-design` | Build from screenshot |
| `/fix-bead` | Fix tracked issue |
| `/deploy-production` | Deploy with checks |
| `/add-effect` | Add animations |
| `/add-python-component` | Add Python backend |
| `/rams` | Accessibility review |
| `/ui-skills` | Tailwind review |
| `/add-rule` | Save lesson learned |
| `/hitl-approve` | Approve human-review task |

## Scripts

| Script | Purpose |
|--------|---------|
| `~/.claude/ralph-loop.sh` | Plan/build orchestrator |
| `~/.claude/ralph-sandbox.sh` | Docker sandbox launcher |
| `~/.claude/ralph-maintenance.sh` | Maintenance processor |
| `~/.claude/ralph-verify.sh` | Build/test verification |
| `~/.claude/scripts/bead-capture.sh` | Create classified beads |
| `~/.claude/scripts/ci-bead-hook.sh` | CI failure → bead |

## CI Integration

Add to GitHub Actions:

```yaml
- name: Capture lint failure
  if: failure() && steps.lint.outcome == 'failure'
  run: ~/.claude/scripts/ci-bead-hook.sh lint "${{ github.run_id }}"

- name: Capture test failure
  if: failure() && steps.test.outcome == 'failure'
  run: ~/.claude/scripts/ci-bead-hook.sh test "${{ github.run_id }}"
```

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_API_KEY` | Claude API access |
| `GITHUB_TOKEN` | Git operations in sandbox |
| `RALPH_MAX_ITERATIONS` | Build mode iteration limit (default: 50) |
| `RALPH_MAINT_ITERATIONS` | Maintenance iteration limit (default: 10) |

## Links

- [Beads Docs](https://github.com/steveyegge/beads)
- [Claude Code Docs](https://docs.anthropic.com/claude-code)
