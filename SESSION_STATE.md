# Factory Floor - Session State
**Last Updated**: 2026-01-19
**Status**: System Cleaned & Backed Up - Ready to Build

---

## Project Goal
Personal "app factory" system using Claude Code + Ralph loops to build web/mobile projects from plain language + reference images.

---

## What I Build
- **Web apps** - Google stack architecture (GCP, Supabase)
- **Mobile apps** - iOS/Android
- **API integrations** - Web apps utilizing external APIs
- **Python scripts** - Automation, data processing, backends

---

## Production Stack

| Layer | Service | Purpose |
|-------|---------|---------|
| **Frontend** | Vercel | Web hosting, edge functions |
| **Backend** | Cloud Run | APIs, workers (via Load Balancer) |
| **Database** | Supabase | Postgres + Auth + RLS |
| **Files** | Google Cloud Storage | Artifacts, uploads |
| **Security** | Cloud Armor | WAF, DDoS, bot blocking |
| **Secrets** | Secret Manager | API keys, credentials |
| **Tasks** | Cloud Tasks | Async jobs, retries |
| **AI** | Vertex AI | Models, inference |
| **Errors** | Sentry | Crash reporting |
| **Analytics** | Mixpanel | Product analytics |
| **Logs** | Cloud Logging | Infrastructure logs |
| **Code** | GitHub | Repos + CI/CD |
| **Issues** | Linear | Issue tracking |

### Security Architecture
```
Internet
    ↓
┌─────────────────────────────────────┐
│   HTTPS Load Balancer               │
│   + Cloud Armor (attached)          │
├─────────────────────────────────────┤
│ • Bot blocking (GPTBot, CCBot...)   │
│ • Rate limit: 100 req/min           │
│ • OWASP: SQLi, XSS, RCE, LFI        │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│   Cloud Run (internal only)         │
│   No direct internet access         │
└─────────────────────────────────────┘
```

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

### ~/.claude/commands/ (9 commands)
| Command | Purpose |
|---------|---------|
| `/add-effect` | Add motion effects (parallax, scroll, hover) |
| `/add-python-component` | Add Python backend |
| `/add-rule` | Capture lessons to CLAUDE.md |
| `/clone-design` | Clone UI from screenshot |
| `/deploy-production` | Production deployment |
| `/fix-issue` | Fix Linear issue via Ralph loop |
| `/new-app` | Build new app |
| `/rams` | Accessibility/visual review |
| `/ui-skills` | Tailwind CSS constraints review |

### ~/.claude/agents/ (7 agents)
| Agent | Purpose |
|-------|---------|
| `build-validator` | Verify project builds |
| `ownership-gate` | Check CODEOWNERS, branch protection before auto-fix |
| `plan-validator` | Verify plan is grounded in repo before execution |
| `security-reviewer` | Code security review |
| `test-runner` | Run tests |
| `verify-app` | Verify app runs |
| `visual-validator` | Playwright visual checks |

### ~/.claude/scripts/
| Script | Purpose |
|--------|---------|
| `issue-watcher.sh` | Poll Linear for auto-fix issues (cron) |

### ~/.claude/skills/ (7 skills)
| Skill | Purpose | Trigger |
|-------|---------|---------|
| `api-endpoint` | Create API endpoints | |
| `db-migration` | Database migrations | |
| `design-extraction` | Extract design tokens from images | |
| `react-best-practices` | React/Next.js optimization | |
| `ui-skills` | Tailwind CSS constraints | `/ui-skills`, "check tailwind" |
| `vercel-deploy-claimable` | Deploy to Vercel | |
| `web-design-guidelines` | Vercel UI guidelines | "review my UI", "check accessibility" |

### Plugins Enabled (11)

| Plugin | Type | How It Works |
|--------|------|--------------|
| `github` | External | GitHub integration (repos, issues, PRs) |
| `frontend-design` | Auto | Activates when building UI - produces distinctive, production-grade code |
| `security-guidance` | Auto | Security analysis, vulnerability detection |
| `pr-review-toolkit` | Command | `/review-pr` - 6 specialized review agents |
| `code-review` | Command | `/code-review` - Automated PR review with confidence scoring |
| `hookify` | Command | `/hookify` - Create behavior-blocking rules |
| `feature-dev` | Command | `/feature-dev` - 7-phase structured development workflow |
| `firebase` | External | Firebase/GCP integration |
| `supabase` | External | Supabase backend integration |
| `playwright` | External | Browser automation/testing |
| `linear` | External | Linear issue tracking integration |

**Plugin behavior types:**
- **Auto** - Activates automatically based on context (no command needed)
- **Command** - Invoked via slash command
- **External** - Service integration (API access)

### MCP Tools Available
- `mcp__rube__*` - Composio/Rube (500+ integrations)
- `mcp__playwright__*` - Browser automation
- `mcp__Claude_in_Chrome__*` - Chrome control

---

## How Things Fit Together

### Plan Mode + Plugins
When Claude enters plan mode:
1. **Commands** (`/clone-design`, `/rams`) - Explicitly referenced in plan steps
2. **Skills** (`design-extraction`, `api-endpoint`) - Referenced when needed
3. **Agents** (`build-validator`, `test-runner`) - Called for verification steps
4. **Auto plugins** (`frontend-design`, `security-guidance`) - Kick in automatically during execution
5. **Command plugins** (`/feature-dev`, `/code-review`) - Explicitly invoked when plan calls for them

### Ralph Loop (Your Custom Version)
External to Claude - bash script that:
1. Creates `IMPLEMENTATION_PLAN.md` (plan mode)
2. Executes steps with fresh context each iteration (build mode)
3. Use for multi-step builds where context pollution hurts quality

```bash
# Plan mode
~/.claude/ralph-loop.sh plan "Build landing page from reference"

# Build mode
~/.claude/ralph-loop.sh
```

### Direct Conversation
For simple tasks, just tell me what to build. Plugins activate automatically as needed.

### Design from Reference
1. Drop image in project (e.g., `references/homepage.png`)
2. Tell me: "Clone design from references/homepage.png"
3. I extract tokens, build it (frontend-design plugin activates)

---

## Linear Auto-Fix Pipeline

### Labels Control Behavior
| Label | Behavior |
|-------|----------|
| `auto-fix` | Full automation - Ralph loop runs automatically |
| `claude-fix` | Semi-auto - Notifies, waits for `/fix-issue` |
| (none) | Manual - Human decides |

### Pipeline Flow
```
Issue Created
     ↓
Label Check
     ↓
┌─────────────────────────────────┐
│ GATE 1: OWNERSHIP               │
│ ✓ CODEOWNERS exists             │
│ ✓ Branch protection enabled     │
│ ✓ Reviewer resolvable           │
│ FAIL → Downgrade to claude-fix  │
└─────────────────────────────────┘
     ↓
┌─────────────────────────────────┐
│ GATE 2: ATTEMPT TRACKING        │
│ Label: ralph-attempts:N         │
│ IF N >= 2 → Escalate            │
│ ELSE → Increment                │
└─────────────────────────────────┘
     ↓
Generate IMPLEMENTATION_PLAN.md
     ↓
┌─────────────────────────────────┐
│ GATE 3: PLAN VALIDATOR          │
│ Is plan grounded in repo?       │
│ NO → Downgrade to claude-fix    │
│ YES → Proceed                   │
└─────────────────────────────────┘
     ↓
Ralph Loop Executes
     ↓
Create PR + Link to Issue
     ↓
Move Issue → "In Review"
     ↓
[Human approves + CI passes]
     ↓
Merge → Issue Closed
```

### Setup
1. Create Linear workspace
2. Add labels: `auto-fix`, `claude-fix`, `ralph-attempts:1`, `ralph-attempts:2`
3. Set up cron: `*/5 * * * * ~/.claude/scripts/issue-watcher.sh`
4. Ensure repo has CODEOWNERS and branch protection

### Manual Trigger
```
/fix-issue PROJ-123
```

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

**Infrastructure (Terraform):**
- `infra/global/` - One-time global setup (Cloud Armor, IAM, VPC)
- `infra/modules/project/` - Per-app module (Cloud Run + LB)
- `infra/README.md` - Setup instructions

**Live installation:**
- `~/.claude/` - Active system files

---

## How to Resume

```
Read SESSION_STATE.md and continue the Factory Floor project.
```

---

---

## Infrastructure Setup (One-Time)

### Prerequisites
```bash
brew install google-cloud-sdk
gcloud auth login
gcloud auth application-default login
gcloud config set project YOUR_PROJECT_ID
```

### Deploy Global Infrastructure
```bash
cd infra/global
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your GCP project ID
terraform init
terraform apply
```

### Add Secrets
```bash
echo -n "your-sentry-dsn" | gcloud secrets versions add sentry-dsn --data-file=-
echo -n "your-mixpanel-token" | gcloud secrets versions add mixpanel-token --data-file=-
```

---

## Git History

| Commit | Date | Milestone |
|--------|------|-----------|
| f5ac7d8 | 2026-01-19 | UI Skills for Tailwind |
| 1547b81 | 2026-01-19 | Linear auto-fix pipeline |
| 386613d | 2026-01-19 | System cleanup + full backup |
| c8825bc | 2026-01-19 | Remove reference templates |
| 217f097 | 2026-01-19 | Initial commit |
