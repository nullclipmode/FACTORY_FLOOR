# Factory Floor - Session State
**Last Updated**: 2026-01-22
**Status**: Infrastructure Deployed - Ralph System Hardened

---

## Project Goal
Personal "app factory" system using Claude Code + Ralph loops to build web/mobile projects from plain language + reference images.

---

## Recent Session Work (2026-01-22)

### Spec Hardening
1. **Structured failure comments**: `[bead_id] [timestamp] [phase]` format
2. **Verification output format**: Acceptance index (#N), Confidence levels (HIGH/MEDIUM/LOW)
3. **Standardized categories**: `TESTS` → `TEST` (singular)
4. **Fallback capture**: sed → last 4KB if structured capture empty
5. **Created SYSTEM_SPECIFICATION.md**: Source of truth for all formats
6. **Removed generic comments**: All 5 comment sites now use structured format

### Commits (2026-01-22)
- `d7d6e93` - fix: Add fallback for FAIL_DETAILS capture
- `f34998d` - fix: Standardize category names and comment format
- `43d5b2b` - docs: Add SYSTEM_SPECIFICATION.md as source of truth
- `1b51b6a` - feat: Add structured failure comments with timestamps

### Previous Session (2026-01-20)
- Added MAX_BEAD_ATTEMPTS=3 with Option B (check before increment)
- Added `bd prime` at HITL exit points
- Fixed negative prompt in AGENTS.md
- Added examples to ralph-review-prompt.md

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

---

## Open Beads

```
ff-2sa: Add LEARNINGS.md template [open]
ff-1j6: Add scriptReferences.md template [open]
ff-klf: Run acceptance tests [open]
ff-3ih: Create login page [open]
ff-7yq: Add auth config [open]
ff-vc6: Create users table [open]
ff-z9i: Verify tests fail [open]
ff-mdr: Create auth test file [open]
ff-y1d: Add user authentication [open]
ff-5ag: Create auth test file [open]
ff-245: Add user authentication [open]
ff-f7v: Create auth test file [open]
ff-fgl: Set up Claude Code GitHub Action [open]
ff-kee: Try bd prime for AI session context [open]
ff-ydr: Explore epic feature planning with beads [open]
```

### Pending Work
1. **ff-1j6**: Create scriptReferences.md template
2. **ff-2sa**: Create LEARNINGS.md template
3. Clean up test beads (test-ralph*)
4. Close stale beads (ff-fgl, ff-kee, ff-ydr)

---

## Key Files

| File | Location | Purpose |
|------|----------|---------|
| ralph-loop.sh | ~/.claude/ | Main orchestrator |
| SYSTEM_SPECIFICATION.md | system-backup/ | Source of truth |
| AGENTS.md | ~/.claude/ | Quality bar |
| ralph-verify-prompt.md | ~/.claude/ | Verification format |
| ralph-review-prompt.md | ~/.claude/ | Code review format |
| ralph-plan-prompt.md | ~/.claude/ | Plan mode instructions |
| ralph-build-prompt.md | ~/.claude/ | Build mode instructions |

---

## Control Loop Limits

| Constant | Default | Description |
|----------|---------|-------------|
| MAX_ITERATIONS | 50 | Total loop iterations before hard stop |
| MAX_BEAD_ATTEMPTS | 3 | Full build→verify→review cycles per bead |
| MAX_RETRIES | 10 | Retries within a single phase |
| VERIFY_RETRIES | 5 | Verification attempts before loop-back |
| REVIEW_RETRIES | 3 | Code review attempts before warning |

---

## Output Formats (from SYSTEM_SPECIFICATION.md)

### Verification Failure
```
<verify>FAIL:CATEGORY</verify>
Acceptance: #N ("[criterion text]")
Error: [what actually happened]
Details: [specific location/message]
Fix direction: [what to change]
Confidence: HIGH | MEDIUM | LOW
```

### Failure Comment
```
[BEAD_ID] [TIMESTAMP] [PHASE] Message.
[Structured details or last 4KB]
```

### Categories
BUILD, STARTUP, VISUAL, FUNCTIONAL, TEST

### Confidence
- HIGH - Deterministic, fix clear
- MEDIUM - Likely cause, fix varies
- LOW - Unclear, may need HITL

---

## Infrastructure (DEPLOYED)

### Live Resources

| Resource | Value |
|----------|-------|
| **GCP Project** | `core-infra-484804` |
| **Load Balancer IP** | `34.8.93.231` |
| **Domain** | `nullclipmode.xyz` |
| **SSL Cert** | `factory-floor-cert` (ACTIVE) |

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

---

## How to Resume

```bash
bd prime   # See current bead state
```

Or tell Claude: "Read SESSION_STATE.md and continue"

---

## File Locations

**Project:**
- `/Users/kitfieldgrass/Documents/____CLAUDE_PROJECTS/_FACTORY_FLOOR/FACTORY_FLOOR/`

**System backup (in this repo):**
- `system-backup/commands/` - All slash commands
- `system-backup/agents/` - All agents
- `system-backup/skills/` - All Vercel skills
- `system-backup/ralph/` - Ralph loop files
- `system-backup/SYSTEM_SPECIFICATION.md` - System spec

**Live installation:**
- `~/.claude/` - Active system files
- `~/.local/bin/bd` - Beads CLI
