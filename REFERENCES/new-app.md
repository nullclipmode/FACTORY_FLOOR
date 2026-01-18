---
description: Critical spec analysis + build from SPEC.md
---

# /new-app

**Location:** `~/.claude/commands/new-app.md`
**Purpose:** Critical spec analysis + build from SPEC.md
**Allowed Tools:** Bash, Read, Write, Edit, Glob, Grep

---

## Phase 0: Pre-Flight Checks

Before any analysis or building, verify pipeline prerequisites.

### Check 1: SPEC.md Exists

Search for SPEC.md in order:
1. Project root: `/SPEC.md`
2. References: `/references/SPEC.md`
3. Docs: `/docs/SPEC.md`

**If not found:**
```
Build requires a spec. No SPEC.md found.

Options:
1. Upload SPEC.md from Claude.ai design phase
2. Provide spec describing what to build
3. Run with --from-scratch to start without spec (quick prototypes only)
```
Stop until resolved.

### Check 2: Spec Gaps Resolved

Look for SPEC_GAPS.md in project root.

| Condition | Action |
|-----------|--------|
| File doesn't exist | âœ“ Pass |
| Status contains "âœ“ All gaps resolved" | âœ“ Pass |
| Status contains "âœ— Gaps found" | âœ— Block |

**If gaps found:**
```
Build blocked. SPEC_GAPS.md shows unresolved gaps.

Run `/spec-check --resolve` to resolve gaps first.
```
Stop until resolved.

### Check 3: Council Review Status

Look for COUNCIL_REVIEW.md in project root.

| Condition | Action |
|-----------|--------|
| File doesn't exist | âš ï¸ Warn, offer to proceed |
| Build Readiness: "Ready" | âœ“ Pass |
| Build Readiness: "Needs Work" | âš ï¸ Warn, offer to proceed |
| Build Readiness: "Not Ready" | âœ— Block |

**If no council review:**
```
No council review found. Run `/council-review` for expert review before build?

Options:
1. Run council review now (recommended)
2. Proceed without review (--skip-council)
```

**If "Needs Work":**
```
Council review status: Needs Work

Critical issues may exist. Review COUNCIL_REVIEW.md before proceeding.

Options:
1. Address issues first (recommended)
2. Proceed anyway (accepting risk)
```

**If "Not Ready":**
```
Build blocked. Council review status: Not Ready

COUNCIL_REVIEW.md shows 3+ critical issues or failed Clarity Test.
Address issues and re-run `/council-review` until status improves.
```
Stop until resolved.

### Check 4: Design System Status (UI Projects Only)

Skip this check if project has no UI (API-only, CLI tool, etc.).

Look for `/design/DESIGN_SYSTEM_STATUS.md`.

| Condition | Action |
|-----------|--------|
| File doesn't exist | âš ï¸ Warn, offer to proceed |
| Status: "âœ“ Approved" | âœ“ Pass |

**If no design system:**
```
No locked design system found.

For consistent UI, run `/design-system` to extract tokens from references.

Options:
1. Run /design-system now (recommended for production)
2. Proceed without locked tokens (--skip-design)
```

### Bypass Flags

```
/new-app --skip-council     # Skip council review check
/new-app --skip-design      # Skip design system check
/new-app --from-scratch     # Skip all checks (quick prototypes only)
/new-app --force            # Skip all checks (same as --from-scratch)
```

**Warning:** Bypass flags are for prototypes and emergencies. Production builds should pass all checks.

---

## Phase 1: Critical Spec Analysis

Once pre-flight passes, analyze the spec before building.

### First Principles Check

For each feature in spec, ask:
- Does this actually solve the stated problem?
- Is this the simplest solution?
- What assumptions are baked in?

### Second-Order Effects

For each feature:
- What does this make possible that wasn't before?
- What does this make harder?
- What dependencies does this create?

### Edge Cases & Failure Modes

For each flow:
- What happens when things go wrong?
- What happens at scale?
- What happens with malicious input?

### Technical Feasibility

For each feature:
- Can this be built with the chosen stack?
- What's the complexity estimate?
- Are there technical risks?

### UX Gaps

For each screen:
- Are all states defined? (empty, loading, error, success)
- Is the flow complete? (entry â†’ action â†’ result)
- What's missing?

### Python/Backend Architecture Check

If spec includes Python, ML, or backend components:
- Which architecture pattern? (Vercel Functions, FastAPI on Railway, Celery workers)
- Are performance requirements clear?
- Are async/background needs identified?

---

## Phase 2: Gap Discussion

Present all findings from Phase 1 analysis.

**Format:**
```
## Spec Analysis Complete

### Issues Found

ðŸ”´ Critical (blocks build):
- [Issue]: [Why it blocks]

ðŸŸ¡ Important (should resolve):
- [Issue]: [Impact if not resolved]

ðŸŸ¢ Minor (note for later):
- [Issue]: [When to address]

### Questions

[List any ambiguities that need resolution]
```

**Wait for user response.** Do not proceed to build until:
- Critical issues are resolved
- Important issues are acknowledged
- Questions are answered

---

## Phase 3: Architecture Decision

Confirm project type and technical approach.

### Architecture Options

| Type | When to Use | Stack |
|------|-------------|-------|
| Frontend Only | No custom backend logic | Next.js + Supabase + Vercel |
| Full Stack | Backend logic < 10s execution | Next.js + Python Vercel Functions |
| Multi-Service | Complex backend, ML, long jobs | Next.js + FastAPI on Railway |
| Mobile + Backend | Native mobile app | Flutter + FastAPI |

**Present recommendation and confirm with user before proceeding.**

---

## Phase 4: Build

After architecture confirmed, execute build.

### Initialization

1. Create GitHub repository via MCP
2. Initialize project structure
3. Set up environment variables
4. Configure Supabase (if needed)
5. Set up error tracking (Sentry)
6. Set up analytics (Mixpanel)

### Implementation

Follow SPEC.md exactly:
- Build every specified feature
- Use exact copy/text from spec
- Use exact colors from spec
- Implement all states (empty, loading, error, success)

### Verification Loop

After every functional change:
```
MAKE CHANGE â†’ VERIFY IT WORKS â†’ FIX IF BROKEN â†’ RE-VERIFY â†’ NEXT CHANGE
```

Apply all relevant verification categories from CLAUDE.md Section 6.

---

## Phase 5: Deploy to Staging

1. Push to GitHub
2. Deploy to Vercel preview URL
3. Run full verification on staging
4. Test critical user flow end-to-end

---

## Phase 6: Report

**Output format:**
```
## Build Complete

### Completed
- [Everything built]

### Verified
- Frontend: [status]
- Backend: [status]
- Database: [status]
- Security: [status]

### Deployed
- Staging URL: [url]
- GitHub repo: [url]

### Next Steps
1. Review staging deployment
2. Address any issues found
3. When ready: `/deploy-production`

### Decisions Needed
[Only if genuine decisions required]
```

---

## Command Syntax

```
/new-app                    # Full pipeline with all checks
/new-app --skip-council     # Skip council review check
/new-app --skip-design      # Skip design system check
/new-app --from-scratch     # Skip all checks (prototypes only)
/new-app --force            # Same as --from-scratch
```
