# Factory Floor - Session State
**Last Updated**: 2026-01-19
**Status**: Architecture Finalized - Ready to Build

---

## Project Goal
Build an automated "factory floor" system that:
1. Monitors multiple data sources (Reddit, news, social, industry feeds)
2. Detects signals/opportunities relevant to your businesses
3. Routes actionable intel to appropriate channels
4. Operates autonomously with minimal intervention
5. **NEW**: Serves as a universal app factory for web/mobile builds

---

## Your Businesses (Context)
- Soulscape Media - wellness/mindfulness content
- Thryve Labs - health tech solutions
- Resonance Digital - digital marketing agency
- Retail arbitrage / ecommerce operations

---

## Key Decisions Made

### 1. Tool Stack Confirmed
- **Rube/Composio MCP** - 500+ app integrations (Reddit, Slack, email, sheets, etc.)
- **Playwright MCP** - Browser automation for sites without APIs
- **Claude in Chrome MCP** - Visual browser control when needed
- **Claude Code** - Orchestration and intelligence layer

### 2. Architecture Direction
Using **Rube recipes** for:
- Pre-built integrations (no API key hunting)
- Scheduling built-in
- Recipe reusability

### 3. Agent/Skill Strategy (Session 2026-01-19)

**Decision: Use Claude Plan Mode as the router — no custom orchestration needed.**

Key insights from today's discussion:
- SpecKit is unnecessary overhead for solo work — just talk + acceptance criteria
- Claude Plan Mode already does implicit skill discovery (reads SKILL.md, READMEs, etc.)
- Plan mode handles step-level routing internally ("what capability is needed now?")
- Chaining happens naturally (read → analyze → modify → verify)
- Validation is embedded — steps don't advance until complete

**What Plan Mode solves:**
| Concern | Solution |
|---------|----------|
| Skill discovery | Repo context ingestion |
| Routing | Step-intent inference |
| Ordering | Plan step sequencing |
| Guardrails | Step completion checks |
| Loop control | Human-visible plan state |

**What Plan Mode doesn't solve (the 20%):**
- Hard determinism (may take different paths)
- Cost ceilings (can't self-limit tokens)
- Machine-readable audit traces
- Unattended autonomous loops

**When to revisit:** Only build custom routing when loops run unattended, costs must be capped, or decisions must be auditable.

### 4. Session Continuity Strategy (Session 2026-01-19)

**Decision: Git-based checkpoints + SESSION_STATE.md**

- This file captures decisions, context, and progress
- Git commits mark major milestones
- Each new session starts with: "Read SESSION_STATE.md and continue"
- ~90% continuity; lose conversational nuance but retain all decisions

---

## Skills Available (REFERENCES folder)

Frontend/Design:
- `design-system.md` - Design system creation
- `clone-design.md` - Clone designs from screenshots
- `add-effect.md` - Motion effects (parallax, scroll, hover)
- `ux-critic.md` - UX analysis
- `accessibility-auditor.md` - A11y audits

Architecture/Quality:
- `new-app.md` - Build new apps from spec
- `spec-check.md` / `spec-check-design.md` - Spec validation
- `council-review.md` / `council-arbitrator.md` - Code review council
- `security-reviewer.md` - Security audits
- `simplicity-enforcer.md` - Prevent over-engineering

Growth/Optimization:
- `conversion-architect.md` - Conversion optimization
- `growth-analyst.md` - Growth analysis
- `seo-architect.md` - SEO optimization

Utilities:
- `add-rule.md` - Add lessons to CLAUDE.md
- `add-python-component.md` - Python backend components
- `deploy-production.md` - Production deployment
- `test-runner.md` - Test execution

**Pending installation:** Vercel agent-skills (react-best-practices, web-design-guidelines, vercel-deploy-claimable)

---

## Tools Available in This Environment

### Already Connected (via MCP)
- `mcp__rube__*` - Composio/Rube tools (search, execute, recipes, scheduling)
- `mcp__playwright__*` - Browser automation
- `mcp__Claude_in_Chrome__*` - Chrome browser control

### Need to Connect (when building)
- Reddit (via Rube)
- Slack (via Rube)
- Gmail (via Rube)
- Google Sheets (via Rube)
- Others as needed

---

## Next Steps

1. [ ] Install Vercel agent-skills (`npx add-skill vercel-labs/agent-skills`)
2. [ ] Choose first app/feature to build with Factory Floor
3. [ ] Create IMPLEMENTATION_PLAN.md for that build
4. [ ] Execute via Ralph loop or plan mode

---

## Open Questions

1. What's the first thing to build? (monitoring system vs. a specific app)
2. Do you want Vercel skills installed now?

---

## How to Resume

When starting a new session, say:

```
Read SESSION_STATE.md and continue the Factory Floor project.
```

That's it. I'll pick up from current state.

---

## File Locations
- Project root: `/Users/kitfieldgrass/Documents/____CLAUDE_PROJECTS/_FACTORY_FLOOR/FACTORY_FLOOR/`
- Session state: `SESSION_STATE.md` (this file)
- Implementation plan: `IMPLEMENTATION_PLAN.md`
- Skills/references: `REFERENCES/`

---

## Git History

| Commit | Date | Milestone |
|--------|------|-----------|
| (initial) | 2026-01-19 | Project init + architecture decisions |
