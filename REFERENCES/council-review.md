---
description: Run expert council review on product specification before building
---

# Council Review Command

Run a comprehensive expert council review on a product specification before building.

## Purpose

Orchestrate multiple expert agents to review a SPEC.md file, then synthesize findings into an actionable COUNCIL_REVIEW.md report.

## When to Use

- After `/spec-check` passes
- Before running `/new-app` on any spec
- After significant spec changes
- When unsure if spec is ready for build

## Prerequisites

- SPEC.md exists in project (root, /references/, or /docs/)
- `/spec-check` has passed (no unresolved gaps)

## Process

### Phase 0: Prerequisite Check

Before running any expert reviews, verify spec-check status:

**Step 1: Locate SPEC.md**

Search in order:
1. Project root: `/SPEC.md`
2. References: `/references/SPEC.md`
3. Docs: `/docs/SPEC.md`

**If not found:** Stop. Output:
```
Council review requires a spec. No SPEC.md found.

Run /spec-check after uploading your spec, or provide the spec describing what you're building.
```

**Step 2: Check SPEC_GAPS.md Status**

Look for SPEC_GAPS.md in project root.

| Condition | Action |
|-----------|--------|
| File doesn't exist | âœ“ Proceed to Phase 1 |
| File exists, status line contains "âœ“ All gaps resolved" | âœ“ Proceed to Phase 1 |
| File exists, status line contains "âœ— Gaps found" | âœ— Stop |

**If gaps found, output:**
```
Council review blocked. SPEC_GAPS.md shows unresolved gaps.

Run `/spec-check --resolve` to resolve gaps, then re-run `/council-review`.

Alternatively, run `/council-review --force` to proceed anyway (not recommended).
```

### Phase 1: Clarity Gate

Run the simplicity-enforcer agent first for Clarity Test:

```
Use the simplicity-enforcer agent to review SPEC.md
```

**Clarity Test checks:**
1. What does it do? (One sentence)
2. Who is it for? (One type of person)
3. Why would they use it? (One clear benefit)

**If Clarity Test fails:** Stop. Report failure. Do not proceed to expert review.

**If Clarity Test passes:** Continue to Phase 2.

### Phase 2: Expert Review

Run all remaining experts on the SPEC.md:

```
Use the conversion-architect agent to review SPEC.md
Use the seo-architect agent to review SPEC.md
Use the ux-critic agent to review SPEC.md
Use the growth-analyst agent to review SPEC.md
Use the security-reviewer agent to review SPEC.md
Use the accessibility-auditor agent to review SPEC.md
```

Each expert produces:
- Score (X/10)
- Risk summary table
- Domain-specific assessment
- Top 2 risks with impact
- Score deductions

### Phase 3: Arbitration

Pass all expert outputs to the arbitrator:

```
Use the council-arbitrator agent to synthesize the following expert reviews:
[Include all 7 expert outputs]
```

The arbitrator:
1. Compiles all risks
2. Deduplicates overlapping concerns
3. Resolves conflicts between experts
4. Classifies severity (Critical / Important / Consider / Deferred)
5. Creates actionable checklists

### Phase 4: Output

Generate `COUNCIL_REVIEW.md` containing:
- Executive summary with build readiness
- All expert scores
- Clarity Test results
- Critical issues (must fix)
- Important issues (should fix)
- Consider items (during/after build)
- Deferred items (post-MVP)
- Conflict resolutions
- Pre-build checklist
- Post-launch checklist
- Final recommendation

## Output Location

```
project/
â”œâ”€â”€ SPEC.md
â”œâ”€â”€ SPEC_GAPS.md         â† May exist (should show resolved)
â”œâ”€â”€ COUNCIL_REVIEW.md    â† Generated here
```

## How to Run

Default (finds SPEC.md automatically):
```
/council-review
```

With specific spec file:
```
/council-review path/to/SPEC.md
```

Specific experts only:
```
/council-review --experts=simplicity,security,ux
```

Skip prerequisite check (not recommended):
```
/council-review --force
```

Available expert flags:
- `simplicity` â€” Simplicity Enforcer
- `conversion` â€” Conversion Architect
- `seo` â€” SEO Architect
- `ux` â€” UX Critic
- `growth` â€” Growth Analyst
- `security` â€” Security Reviewer
- `accessibility` â€” Accessibility Auditor
- `all` â€” All experts (default)

## Build Readiness Determination

**Ready:** No critical issues, average score â‰¥ 6/10

**Needs Work:** Has critical issues OR average score < 6/10

**Not Ready:** Fails Clarity Test OR has 3+ critical issues OR average score < 4/10

## After Review

**If "Ready":**
Proceed to `/new-app`

**If "Needs Work":**
1. Address Critical issues in SPEC.md
2. Address Important issues in SPEC.md
3. Re-run `/council-review`
4. Repeat until "Ready"

**If "Not Ready":**
Major rework needed. Return to Claude.ai design conversation to clarify scope.

## Example Workflow

```
User: [Uploads SPEC.md from Claude.ai design phase]

User: /spec-check
[Verification: PASSED]

User: /council-review
[Phase 0: Prerequisites met]
[Phase 1: Clarity Test passes]
[Phase 2: All experts review spec]
[Phase 3: Arbitrator synthesizes]
[Phase 4: COUNCIL_REVIEW.md generated: "Needs Work"]

User: [Reviews council output, updates SPEC.md]

User: /council-review
[Re-review]
[COUNCIL_REVIEW.md generated: "Ready"]

User: /new-app
[Build begins with verified, council-approved spec]
```

## Skipping Council Review

Council review is strongly recommended. To build without review:

```
/new-app --skip-council
```

Use only for:
- Quick prototypes (not deployed)
- Rebuilding a previously-reviewed spec
- Time-critical situations (accepting risk)

## Token Cost

Approximately 40-60k tokens per full review:
- Phase 0 prerequisite check: ~1k tokens
- Phase 1 clarity gate: ~3k tokens
- Phase 2 expert reviews (6 experts): ~30k tokens
- Phase 3 arbitration: ~8k tokens
- Phase 4 report generation: ~3k tokens
