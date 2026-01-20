# Factory Floor - Complete Command Cheat Sheet

**Every command at your disposal, in plain English.**

*Last Updated: 2026-01-20*

---

## Quick Reference

| I want to... | Use this |
|--------------|----------|
| Build a new app | `/new-app` |
| Clone a design from a screenshot | `/clone-design` |
| Fix an issue/bug | `/fix-bead` |
| Deploy to production | `/deploy-production` |
| Add animations/effects | `/add-effect` |
| Add Python backend | `/add-python-component` |
| Check accessibility | `/rams` |
| Review Tailwind code | `/ui-skills` |
| Remember a lesson learned | `/add-rule` |
| See what's ready to work on | `bd ready` |
| Approve a human-review task | `/hitl-approve` |

---

## Slash Commands (Type in Claude Code)

### `/new-app`
**What it does:** Creates a complete new project from scratch - GitHub repo, Vercel hosting, Supabase database, and all the infrastructure.

**When to use:** Starting a brand new project.

**Example:**
```
/new-app my-cool-app
```

---

### `/clone-design`
**What it does:** Takes a screenshot/image and recreates it as working code. Extracts colors, fonts, spacing, and builds the UI.

**When to use:** You have a design (Figma, screenshot, mockup) and want it built.

**Example:**
```
/clone-design references/homepage.png
```

---

### `/fix-bead`
**What it does:** Takes an issue from your Beads tracker and fixes it using the Ralph loop (automated code generation).

**When to use:** You have a bug or task tracked in Beads that needs fixing.

**Options:**
- Default: Shows you the issue and asks for approval before fixing
- `--auto`: Fixes without asking (for trusted automated workflows)

**Example:**
```
/fix-bead ff-abc          # Manual mode - asks first
/fix-bead ff-abc --auto   # Auto mode - just does it
/fix-bead                 # Gets next ready issue
```

---

### `/hitl-approve`
**What it does:** Approves a HITL (Human-in-the-Loop) bead after you've reviewed it. HITL beads are for things that need human judgment - like "does this UI look right?"

**When to use:** Agent hit a HITL bead and is waiting for your approval.

**Example:**
```
/hitl-approve ff-abc      # Approve the bead
```

**The HITL workflow:**
1. Agent works through AUTO beads (testable tasks)
2. Hits a HITL bead → pauses, asks for your review
3. You review the work, run `/hitl-approve ff-abc`
4. Agent continues with downstream tasks

---

### `/deploy-production`
**What it does:** Deploys your app to production with all safety checks (tests, build, security scan).

**When to use:** Your app is ready to go live.

**Example:**
```
/deploy-production
```

---

### `/add-effect`
**What it does:** Adds motion and animation effects to your UI - parallax scrolling, hover effects, scroll animations, transitions.

**When to use:** Your UI works but feels static/boring.

**Example:**
```
/add-effect "Add parallax to hero section"
```

---

### `/add-python-component`
**What it does:** Adds a Python backend to your project - ML models, data processing, automation scripts.

**When to use:** You need Python for something Node.js can't do well (ML, heavy data processing).

**Example:**
```
/add-python-component "Add image classification endpoint"
```

---

### `/rams`
**What it does:** Runs accessibility and visual design review. Checks colors, contrast, screen reader compatibility, mobile responsiveness.

**When to use:** Before launching, or when you want to make sure your UI is usable by everyone.

**Example:**
```
/rams
```

---

### `/ui-skills`
**What it does:** Reviews your Tailwind CSS code against best practices. Catches common mistakes, suggests improvements.

**When to use:** After writing UI code, want to make sure it's clean.

**Example:**
```
/ui-skills
```

---

### `/add-rule`
**What it does:** Saves a lesson learned to CLAUDE.md so Claude won't make the same mistake again.

**When to use:** Claude did something wrong that you want to prevent in the future.

**Example:**
```
/add-rule "Never use deprecated API endpoints"
```

---

## AUTO vs HITL Tasks

Factory Floor has two task types:

| Type | What it is | How it completes |
|------|------------|------------------|
| **AUTO** | Testable tasks | Tests pass → done |
| **HITL** | Judgment tasks | Human approves → done |

**AUTO tasks** have executable acceptance criteria (test files, curl commands). The agent can complete these without you.

**HITL tasks** require human judgment - UI review, copy approval, "does this feel right?" The agent pauses and waits for you.

### Creating Tasks

```bash
# AUTO task - has tests, agent can complete alone
bd create "Add login API" --acceptance "tests/api/login.spec.ts"

# HITL task - needs human eye, agent will pause
bd create "Review login page design" --label hitl

# AUTO task that waits for HITL approval
bd create "Wire login to backend" \
  --acceptance "tests/e2e/login.spec.ts" \
  --blocks "ff-abc"   # ff-abc is the HITL task
```

### The Flow

```
AUTO: Build API     ──→  AUTO: Add migration  ──→  HITL: Review UI  ──→  AUTO: Wire UI
      (agent)                 (agent)                  (YOU)                (agent)
```

Agent runs through AUTO tasks automatically. When it hits a HITL task, it stops and asks you. After you approve (`/hitl-approve`), it continues.

---

## Beads Commands (Issue Tracking)

Run these in your terminal, not in Claude Code.

### `bd ready`
**What it does:** Shows issues that have no blockers and are ready to work on.

**When to use:** Starting a work session, need to know what to do.

```bash
bd ready
```

---

### `bd create "title"`
**What it does:** Creates a new issue/task.

**When to use:** You think of something that needs to be done.

**Options:**
- `-p 0` = Critical (P0)
- `-p 1` = High priority (P1)
- `-p 2` = Medium (P2, default)
- `-p 3` = Low (P3)

```bash
bd create "Fix login bug" -p 1
bd create "Add dark mode" -p 2
```

---

### `bd show <id>`
**What it does:** Shows full details of an issue.

**When to use:** Need to see what an issue is about.

```bash
bd show ff-abc
```

---

### `bd update <id> --status <status>`
**What it does:** Updates an issue's status.

**When to use:** Starting or pausing work on something.

**Statuses:** `open`, `in_progress`, `blocked`, `done`

```bash
bd update ff-abc --status in_progress
```

---

### `bd close <id>`
**What it does:** Marks an issue as done.

**When to use:** You finished the work.

```bash
bd close ff-abc
```

---

### `bd list`
**What it does:** Shows all issues.

**When to use:** Want to see everything, not just ready items.

```bash
bd list
bd list --status in_progress  # Just in-progress ones
```

---

### `bd prime`
**What it does:** Outputs AI-optimized context about your current issues.

**When to use:** Starting a Claude session, want to give Claude context about what you're working on.

```bash
bd prime
# Then paste the output into Claude
```

---

### `bd sync`
**What it does:** Syncs your issues to git (export, commit, push).

**When to use:** End of a session, want to make sure everything is saved.

```bash
bd sync
```

---

## Scripts (Run in Terminal)

### `~/.claude/scripts/bead-capture.sh`
**What it does:** Captures an error as a bead automatically.

**When to use:** Build failed, test failed, want to track it.

```bash
# Manual capture
~/.claude/scripts/bead-capture.sh manual "Bug title" "Description"

# Auto-capture with auto-fix label
AUTO_FIX=true ~/.claude/scripts/bead-capture.sh build "Build failed"
```

---

### `~/.claude/scripts/bead-watcher.sh`
**What it does:** Polls for beads with `auto-fix` label and processes them automatically.

**When to use:** Set up as a cron job for fully automated fixes.

```bash
# Add to crontab for auto-processing every 5 minutes
# */5 * * * * cd /path/to/project && ~/.claude/scripts/bead-watcher.sh
```

---

### `~/.claude/ralph-loop.sh`
**What it does:** The Ralph loop - creates a plan, then executes it step by step with fresh context each iteration.

**When to use:** Complex multi-step tasks where context pollution hurts quality.

```bash
# Create a plan
~/.claude/ralph-loop.sh plan "Build user authentication"

# Execute the plan
~/.claude/ralph-loop.sh
```

---

## Auto-Activated Skills (No Command Needed)

These kick in automatically when relevant:

| Skill | Activates When |
|-------|----------------|
| `frontend-design` | Building any UI |
| `security-guidance` | Writing code that could have security issues |
| `react-best-practices` | Working with React/Next.js |
| `design-extraction` | Processing design images |
| `api-endpoint` | Creating API routes |
| `db-migration` | Working with database schemas |
| `web-design-guidelines` | Say "review my UI" or "check accessibility" |

---

## Plugin Commands

These come from installed plugins:

### `/review-pr`
**What it does:** Comprehensive PR review using 6 specialized agents.

**When to use:** Before merging a pull request.

---

### `/code-review`
**What it does:** Automated code review with confidence scoring.

**When to use:** Want quick feedback on code quality.

---

### `/hookify`
**What it does:** Creates rules to block unwanted Claude behaviors.

**When to use:** Claude keeps doing something you don't want.

---

### `/feature-dev`
**What it does:** 7-phase structured development workflow.

**When to use:** Building a significant new feature.

---

## GCP / Infrastructure Commands

### Check infrastructure status
```bash
gcloud compute forwarding-rules list --project=core-infra-484804
```

### View Cloud Run services
```bash
gcloud run services list --project=core-infra-484804
```

### Check Cloud Armor rules
```bash
gcloud compute security-policies describe factory-floor-armor --project=core-infra-484804
```

---

## Git Shortcuts

### Quick backup
```bash
git add -A && git commit -m "checkpoint" && git push
```

### See recent changes
```bash
git log --oneline -10
```

---

## Keeping This Updated

When you add new commands or tools to Factory Floor:

1. Add the command/tool
2. Update this cheat sheet
3. Commit both together

```bash
# After adding something new
git add -A
git commit -m "feat: Add X + update cheat sheet"
git push
```

---

## Emergency Commands

### Something's broken, start fresh
```bash
# Reset Claude config from backup
cp -r system-backup/commands/* ~/.claude/commands/
cp -r system-backup/agents/* ~/.claude/agents/
cp system-backup/settings.json ~/.claude/
```

### Beads database corrupted
```bash
bd doctor --fix
```

### Need to see what Claude has access to
```bash
ls ~/.claude/commands/
cat ~/.claude/settings.json
```
