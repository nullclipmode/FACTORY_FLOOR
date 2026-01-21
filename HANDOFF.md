# Factory Floor - Complete System Reference

## Overview

Factory Floor is a personal app factory for building web/mobile apps from plain language descriptions and reference images. Designed for autonomous AI operation with minimal human intervention.

## Architecture

### Infrastructure
- **Frontend**: Vercel (individual app repos)
- **Backend**: Google Cloud Run (shared Load Balancer)
- **Database**: Supabase (Postgres + Auth)
- **Files**: Google Cloud Storage
- **Security**: Cloud Armor (WAF, bot blocking, rate limiting)
- **IaC**: Terraform modules in `infra/`

### Directory Structure
```
FACTORY_FLOOR/
├── CLAUDE.md              # Project-level AI instructions
├── infra/                 # Terraform (GCP Cloud Run, LB, Cloud Armor)
├── .beads/                # Git-backed issue tracker
├── .claude/commands/      # Custom slash commands
├── templates/             # Scaffolding templates
│   └── CLAUDE.md.template # Per-app CLAUDE.md template
└── system-backup/         # Backup of global configs
```

## Core Systems

### 1. Beads (Issue Tracking)
Git-native, AI-optimized issue tracker. Replaces Linear/Jira.

**Storage**: `.beads/issues.jsonl`

**Commands**:
```bash
bd create "title"    # Create issue
bd list              # Show open issues
bd close <id>        # Complete issue
```

**Statuses**: `open`, `in_progress`, `hitl`, `closed`

### 2. HITL (Human-in-the-Loop)
Tasks requiring human judgment are marked `status: hitl`. AI must await human input before proceeding.

**Triggers**: Design approval, ambiguous specs, security decisions.

### 3. Test-First Validation
- Tests written BEFORE implementation
- Test files are locked—cannot be modified to pass
- Completion validated against original tests
- Prevents gaming the system
- **Enforcement**: `~/.claude/ralph-loop.sh` (source of truth for loop mechanics)

### 4. Ralph Loop
Two-mode workflow for complex tasks. Fresh context each iteration.

```bash
~/.claude/ralph-loop.sh plan "task"  # Creates IMPLEMENTATION_PLAN.md + CLAUDE.md
~/.claude/ralph-loop.sh              # Executes plan step-by-step
```

**Use for**: Multi-file changes, sequential dependencies.

**Outputs**:
- `IMPLEMENTATION_PLAN.md` - Atomic steps with acceptance criteria
- `CLAUDE.md` - App-specific context (for new apps)

## CLAUDE.md Hierarchy

Three levels, read recursively upward:

| Level | Location | Purpose |
|-------|----------|---------|
| Global | `~/.claude/CLAUDE.md` | Style, universal patterns |
| Factory Floor | `FACTORY_FLOOR/CLAUDE.md` | System behavior, default stack |
| Per-app | `apps/*/CLAUDE.md` | App-specific overrides |

**Rules**:
- No overlap between levels
- Child files override parent
- Max 30 lines for per-app
- Every line must affect AI decisions

## Autonomous Operation Principles

1. **Complete full tasks** without unnecessary questions
2. **When blocked**: Create bead with details, mark HITL, await human input
3. **HITL only** when human judgment genuinely required
4. **Minimal changes** - scope defined by tests
5. **Quality enforced** by test-first + build/test passing

## Verification Requirements

Before marking work complete:
```bash
npm run build   # Must pass
npm run test    # Must pass
```

## Creating New Apps

1. Plan mode generates `IMPLEMENTATION_PLAN.md` + `CLAUDE.md`
2. CLAUDE.md created from `templates/CLAUDE.md.template`
3. Contains: Stack, Structure, Commands, Notes
4. Max 30 lines, only app-specific content

## File Reference

| File | Location | Purpose |
|------|----------|---------|
| `CLAUDE.md` | Project root | Factory Floor AI instructions |
| `CLAUDE.md.template` | `templates/` | Per-app CLAUDE.md scaffold |
| `ralph-loop.sh` | `~/.claude/` | Orchestrator script |
| `ralph-plan-prompt.md` | `~/.claude/` | Plan mode instructions |
| `ralph-build-prompt.md` | `~/.claude/` | Build mode instructions |
| `issues.jsonl` | `.beads/` | Issue storage |

## Key Constraints

- **No negative commands** in CLAUDE.md (tell AI what TO do)
- **No vague instructions** (every line actionable)
- **No style rules** in CLAUDE.md (use linters)
- **No redundant content** (every token matters)
- **Test-first mandatory** for all implementation
