# Factory Floor - Session State
**Last Updated**: 2026-01-20
**Status**: Infrastructure Deployed - Ready to Build Apps

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
| **Issues** | Beads | Git-backed issue tracking (per-app) |

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
- **Beads (bd)** - Git-backed issue tracking

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

### 5. Beads Integration (2026-01-20)
Replaced Linear with Beads for issue tracking:
- Git-backed, AI-agent-optimized
- Per-app `.beads/` directories (self-contained instances)
- Auto/manual mode switch with approval-first
- Automated capture of build/test/runtime failures

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

### ~/.claude/commands/ (8 commands)
| Command | Purpose |
|---------|---------|
| `/add-effect` | Add motion effects (parallax, scroll, hover) |
| `/add-python-component` | Add Python backend |
| `/add-rule` | Capture lessons to CLAUDE.md |
| `/clone-design` | Clone UI from screenshot |
| `/deploy-production` | Production deployment |
| `/fix-bead` | Fix a bead via Ralph loop (auto/manual mode) |
| `/new-app` | Build new app (with Beads init) |
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
| `bead-watcher.sh` | Poll for auto-fix beads (cron) |
| `bead-capture.sh` | Capture errors as beads |
| `ci-bead-hook.sh` | CI/CD hook for failure capture |

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

### Plugins Enabled (10)

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

## Beads Auto-Fix Pipeline

### Labels Control Behavior
| Label | Behavior |
|-------|----------|
| `auto-fix` | Full automation - Ralph loop runs automatically |
| `needs-human` | Requires manual intervention |
| `ralph-attempts:N` | Tracks fix attempts (max 2) |

### Pipeline Flow
```
Bead Created (via capture or manual)
     ↓
Mode Check
     ↓
┌─────────────────────────────────┐
│ AUTO-FIX LABEL?                 │
│ YES → Full automation           │
│ NO  → Manual approval required  │
└─────────────────────────────────┘
     ↓
┌─────────────────────────────────┐
│ GATE 1: OWNERSHIP               │
│ ✓ CODEOWNERS exists             │
│ ✓ Branch protection enabled     │
│ FAIL → Add needs-human label    │
└─────────────────────────────────┘
     ↓
┌─────────────────────────────────┐
│ GATE 2: ATTEMPT TRACKING        │
│ Label: ralph-attempts:N         │
│ IF N >= 2 → Add needs-human     │
│ ELSE → Increment                │
└─────────────────────────────────┘
     ↓
Generate IMPLEMENTATION_PLAN.md
     ↓
┌─────────────────────────────────┐
│ GATE 3: PLAN VALIDATOR          │
│ Is plan grounded in repo?       │
│ NO → Add needs-human label      │
│ YES → Proceed                   │
└─────────────────────────────────┘
     ↓
Ralph Loop Executes
     ↓
Create PR + Link to Bead
     ↓
Update Bead → "in_progress"
     ↓
[Human approves + CI passes]
     ↓
Merge → Bead Closed
```

### Issue Sources
```
┌─────────────────────────────────────────────────────┐
│                   ISSUE SOURCES                     │
├─────────────────┬─────────────────┬─────────────────┤
│   CI Failures   │  Runtime Errors │   Manual Input  │
│  (build, test)  │    (Sentry)     │   (bd create)   │
└────────┬────────┴────────┬────────┴────────┬────────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           ↓
                  ┌─────────────────┐
                  │  .beads/ store  │
                  │  (per-app)      │
                  └────────┬────────┘
                           ↓
              ┌────────────┴────────────┐
              ↓                         ↓
     ┌────────────────┐       ┌────────────────┐
     │   AUTO MODE    │       │  MANUAL MODE   │
     │ (auto-fix tag) │       │ (approval req) │
     └───────┬────────┘       └───────┬────────┘
             ↓                        ↓
      bead-watcher.sh           /fix-bead
             ↓                        ↓
             └──────────┬─────────────┘
                        ↓
               ┌────────────────┐
               │  Ralph Loop    │
               │  (fresh ctx)   │
               └───────┬────────┘
                       ↓
               ┌────────────────┐
               │  Pull Request  │
               └────────────────┘
```

### Setup (Per App)
```bash
# Initialize beads in your app
cd /path/to/your-app
bd init --prefix app
bd hooks install

# Create labels for automation
bd label create auto-fix
bd label create needs-human
bd label create ralph-attempts:1
bd label create ralph-attempts:2

# Set up cron for auto-fix (optional)
# */5 * * * * cd /path/to/your-app && ~/.claude/scripts/bead-watcher.sh
```

### Manual Trigger
```bash
# Manual mode (requires approval)
/fix-bead bd-a1b2

# Auto mode (no approval)
/fix-bead bd-a1b2 --auto

# Get next ready bead
/fix-bead
```

### Capture Errors as Beads
```bash
# Manual capture
~/.claude/scripts/bead-capture.sh manual "Bug title" "Description"

# Auto-capture (with auto-fix label)
AUTO_FIX=true ~/.claude/scripts/bead-capture.sh build "Build failed"

# From CI/CD
~/.claude/scripts/ci-bead-hook.sh build "$JOB_NAME" "$RUN_ID"
```

---

## Other Beads Uses

Beyond issue tracking, Beads can be used for:

1. **Feature Planning** - Create epic beads with sub-tasks
   ```bash
   bd create "User authentication" -t epic -p 1
   bd create "Login form" --parent bd-a1b2
   bd create "OAuth integration" --parent bd-a1b2
   ```

2. **Technical Debt Tracking** - Label and prioritize
   ```bash
   bd create "Refactor database layer" -p 2
   bd label add bd-a1b2 tech-debt
   ```

3. **Session Planning** - Track what to work on
   ```bash
   bd ready  # What's ready to work on
   bd list --status in_progress  # What's in progress
   ```

4. **Cross-App Dependencies** - Link related issues
   ```bash
   bd dep add bd-app1-a1b2 bd-app2-c3d4  # app1 depends on app2
   ```

5. **AI Agent Memory** - Persistent task context
   ```bash
   bd prime  # Get AI-optimized context for current session
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
- `~/.local/bin/bd` - Beads CLI

---

## How to Resume

```
Read SESSION_STATE.md and continue the Factory Floor project.
```

---

---

## Infrastructure (DEPLOYED)

### Live Resources

| Resource | Value |
|----------|-------|
| **GCP Project** | `core-infra-484804` |
| **Load Balancer IP** | `34.8.93.231` |
| **Domain** | `nullclipmode.xyz` |
| **SSL Cert** | `factory-floor-cert` (ACTIVE) |
| **Service Account** | `factory-floor-run@core-infra-484804.iam.gserviceaccount.com` |

### What's Deployed

| Component | Name | Status |
|-----------|------|--------|
| Cloud Armor | `factory-floor-armor` | Active |
| Load Balancer | `factory-floor-lb` | Active |
| VPC | `factory-floor-vpc` | Active |
| VPC Connector | `factory-floor-connector` | Active |
| Cloud Tasks | `factory-floor-tasks` | Active |
| Secrets (shells) | `sentry-dsn`, `mixpanel-token`, `supabase-service-key` | Empty |

### Architecture

```
Internet
    ↓
nullclipmode.xyz (DNS → 34.8.93.231)
    ↓
┌─────────────────────────────────────┐
│   HTTPS Load Balancer               │
│   + Cloud Armor (attached)          │
├─────────────────────────────────────┤
│ • Bot blocking (GPTBot, CCBot...)   │
│ • OWASP: SQLi, XSS                  │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│   Cloud Run Services (per app)      │
│   Internal only - no direct access  │
└─────────────────────────────────────┘
```

### Pending

- [x] SSL cert activation
- [ ] Secret values (added per-app as needed)
- [ ] First app deployment

### Cost

~$30/month fixed (LB + Cloud Armor + VPC connector). Cloud Run scales to zero.

---

## Git History

| Commit | Date | Milestone |
|--------|------|-----------|
| (next) | 2026-01-20 | Beads integration (replace Linear) |
| 0e533cf | 2026-01-20 | Infrastructure deployed |
| f5ac7d8 | 2026-01-19 | UI Skills for Tailwind |
| 1547b81 | 2026-01-19 | Linear auto-fix pipeline |
| 386613d | 2026-01-19 | System cleanup + full backup |
| c8825bc | 2026-01-19 | Remove reference templates |
| 217f097 | 2026-01-19 | Initial commit |
