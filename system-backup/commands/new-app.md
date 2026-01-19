---
description: Build a new app project from SPEC.md with critical analysis and full architecture
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# New App Project

## Pre-Check: SPEC.md Required

**STOP.** Before doing anything:
1. Ask: "Do you have a SPEC.md for this project?"
2. If NO → "Run /spec-interview first. Return here when complete."
3. If YES → Proceed to Phase 1.

**NEVER BUILD WITHOUT A SPEC.**

## Phase 1: Critical Spec Analysis

Read entire SPEC.md. Then perform deep analysis:

### 1.1 First Principles Check
- Is each feature necessary for the core problem?
- What's the simplest version that delivers value?
- Features built because common or because needed?
Flag: Disconnected features, scope too large, mixed priorities

### 1.2 Second-Order Effects
- If users do X, what else might they want?
- If this data exists, what else might be done?
- If this grows, what breaks first?
- If this fails, what's the impact?
Flag: Unaddressed follow-on needs, unconsidered failures, scale issues

### 1.3 Edge Cases & Failure Modes
For each flow: New user? Power user? Empty input? Wrong format? Network fail? Race conditions? Abuse attempts? Corrupted data?
Flag: Critical edge cases, undefined errors, abuse potential

### 1.4 Technical Feasibility
- Timeline vs complexity realistic?
- Hidden dependencies?
- Service/API limitations?
- Performance realistic?
- Data model supports all features?
Flag: Unrealistic timeline, forced compromises, unstated dependencies

### 1.5 UX Gaps
- How does new user know what to do?
- How recover from mistakes?
- How know something worked?
- How get help?
- Loading states? Empty states?
Flag: Missing onboarding, undefined feedback, error handling

### 1.6 Python/Backend Architecture Check
If Python/ML/processing needed:
- Processing realistic for budget?
- Real-time or async?
- Where should code run?
- How connects to frontend?
- What if processing fails?
- How will it scale?
Flag: Unclear architecture, unrealistic expectations, undefined integration

## Phase 2: Gap Discussion

Present findings:
- What Looks Good
- Questions & Gaps Found (First Principles, Edge Cases, Technical, UX, Backend)
- My Recommendations

**Wait for user input. Resolve each gap. Update SPEC.md before proceeding.**

## Phase 3: Architecture Decision

**Project Types:**
- Frontend Only: No Python, Supabase handles backend, Vercel deploy
- Full Stack: Next.js + Python Vercel functions (< 10s processing)
- Multi-Service: Next.js + FastAPI on Railway (heavy processing, ML)
- Mobile + Backend: Flutter + FastAPI

**Python Options:**
- Vercel Functions: < 10s, simple deps, serverless
- FastAPI Backend: > 10s, ML models, complex deps, Railway/Render
- Background Workers: Minutes/hours, queued, Celery/Redis

**Confirm architecture with user before building.**

## Phase 4: Build

### 4.1 Infrastructure (Terraform)

If backend needed:
```bash
# Create project terraform config
mkdir -p infra/projects/${APP_NAME}
cd infra/projects/${APP_NAME}

# Generate main.tf from template
# Uses global Cloud Armor, IAM, VPC from infra/global

terraform init
terraform apply -auto-approve
```

This creates:
- Cloud Run service (internal + LB only)
- HTTPS Load Balancer with Cloud Armor
- Per-project secrets in Secret Manager
- HTTP→HTTPS redirect

### 4.2 External Services

```bash
# GitHub repo
gh repo create ${APP_NAME} --private --clone

# Vercel project (linked to GitHub)
vercel link --yes

# Supabase project
supabase projects create ${APP_NAME} --org-id YOUR_ORG

# Linear project
# (via Linear plugin)
```

### 4.3 Application Code

1. Initialize framework with dependencies
2. Create full project structure (frontend + backend if needed)
3. Create .claude/CLAUDE.md with project specifics
4. Create CI/CD pipeline (GitHub Actions → Vercel + Cloud Run)
5. Create database schema (Supabase migrations)
6. Create documentation (README, SPEC, TECHNICAL)
7. Create legal pages
8. Initial commit and push
9. Wire secrets to Secret Manager
10. Deploy to staging

## Phase 5: Report

✅ Completed:
- GitHub: https://github.com/YOU/${APP_NAME}
- Vercel: https://${APP_NAME}.vercel.app
- Cloud Run: https://${APP_NAME}.run.app (via Load Balancer)
- Supabase: https://app.supabase.com/project/${PROJECT_ID}
- Linear: ${PROJECT_KEY}

📊 Infrastructure:
- Cloud Armor: Attached ✓
- Rate Limiting: 100 req/min ✓
- Bot Blocking: Active ✓
- OWASP Rules: Active ✓

➡️ Next Steps (which feature first?)

## Reminders
- Enter Plan mode for features (shift+tab twice)
- Say "think hard" for complex planning
- Paste screenshots for design work
- Run /clear between unrelated tasks
- Run /add-rule if mistakes happen

## NEVER:
- Skip spec analysis
- Build without resolving gaps
- Assume spec is complete
- Make architecture decisions without confirmation
