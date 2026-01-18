# Factory Floor - Session State
**Last Updated**: 2026-01-19
**Status**: System Cleaned & Backed Up - Ready to Build

---

## Project Goal
Personal "app factory" system using Claude Code + Ralph loops to build web/mobile projects from plain language + reference images.

---

## Your Businesses (Context)
- Soulscape Media - wellness/mindfulness content
- Thryve Labs - health tech solutions
- Resonance Digital - digital marketing agency
- Retail arbitrage / ecommerce operations

---

## Key Decisions Made

### 1. Tool Stack
- **Rube/Composio MCP** - 500+ app integrations
- **Playwright MCP** - Browser automation
- **Claude in Chrome MCP** - Visual browser control
- **Claude Code** - Orchestration layer

### 2. Architecture
**Use Claude Plan Mode as router — no custom orchestration.**

Plan mode handles:
- Skill discovery (reads SKILL.md, READMEs)
- Step-level routing
- Validation (steps don't advance until complete)

### 3. Session Continuity
- Git-based checkpoints + this SESSION_STATE.md
- New session: "Read SESSION_STATE.md and continue"

### 4. System Cleanup (2026-01-19)
Removed old "spec ceremony" system:
- Deleted spec-check, spec-check-design, design-system commands
- Deleted council-review, spec-interview commands
- Deleted council agents (accessibility-auditor, conversion-architect, council-arbitrator, growth-analyst, seo-architect, simplicity-enforcer, ux-critic)
- Kept only build/verification focused components

---

## What's Installed (CURRENT STATE)

### ~/.claude/ Root
| File | Purpose |
|------|---------|
| `CLAUDE.md` | Global instructions (plan mode, ralph pattern) |
| `settings.json` | Plugins, hooks (prettier), permissions |
| `ralph-loop.sh` | Main orchestrator script |
| `ralph-plan-prompt.md` | Plan mode instructions |
| `ralph-build-prompt.md` | Build mode instructions |
| `ralph-review-prompt.md` | Review prompt |
| `ralph-verify-prompt.md` | Verify prompt |

### ~/.claude/commands/ (7 commands)
| Command | Purpose |
|---------|---------|
| `/add-effect` | Add motion effects (parallax, scroll, hover) |
| `/add-python-component` | Add Python backend |
| `/add-rule` | Capture lessons to CLAUDE.md |
| `/clone-design` | Clone UI from screenshot |
| `/deploy-production` | Production deployment |
| `/new-app` | Build new app |
| `/rams` | Accessibility/visual review |

### ~/.claude/agents/ (5 agents)
| Agent | Purpose |
|-------|---------|
| `build-validator` | Verify project builds |
| `security-reviewer` | Code security review |
| `test-runner` | Run tests |
| `verify-app` | Verify app runs |
| `visual-validator` | Playwright visual checks |

### ~/.claude/skills/ (6 Vercel skills)
| Skill | Purpose |
|-------|---------|
| `api-endpoint` | Create API endpoints |
| `db-migration` | Database migrations |
| `design-extraction` | Extract design tokens from images |
| `react-best-practices` | React/Next.js optimization |
| `vercel-deploy-claimable` | Deploy to Vercel |
| `web-design-guidelines` | UI review |

### Plugins Enabled (8)
github, frontend-design, security-guidance, ralph-wiggum, pr-review-toolkit, code-review, hookify, feature-dev

### MCP Tools Available
- `mcp__rube__*` - Composio/Rube (500+ integrations)
- `mcp__playwright__*` - Browser automation
- `mcp__Claude_in_Chrome__*` - Chrome control

---

## How to Use

### Direct conversation
Just tell me what to build. I read references, extract designs, write code.

### Ralph loop (multi-step builds)
```bash
# Plan mode - creates IMPLEMENTATION_PLAN.md
~/.claude/ralph-loop.sh plan "Build landing page from reference"

# Build mode - executes plan
~/.claude/ralph-loop.sh
```

### Design from reference
1. Drop image in project (e.g., `references/homepage.png`)
2. Tell me: "Clone design from references/homepage.png"
3. I extract tokens, build it

---

## File Locations

**Project:**
- `/Users/kitfieldgrass/Documents/____CLAUDE_PROJECTS/_FACTORY_FLOOR/FACTORY_FLOOR/`

**System backup (in this repo):**
- `system-backup/commands/` - All slash commands
- `system-backup/agents/` - All agents
- `system-backup/skills/` - All Vercel skills
- `system-backup/ralph/` - Ralph loop files
- `system-backup/settings.json` - Claude settings
- `system-backup/CLAUDE.md` - Global instructions

**Live installation:**
- `~/.claude/` - Active system files

---

## How to Resume

```
Read SESSION_STATE.md and continue the Factory Floor project.
```

---

## Git History

| Commit | Date | Milestone |
|--------|------|-----------|
| c8825bc | 2026-01-19 | Remove reference templates |
| 217f097 | 2026-01-19 | Initial commit |
| (next) | 2026-01-19 | System cleanup + full backup |
