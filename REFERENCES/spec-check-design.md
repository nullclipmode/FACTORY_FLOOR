---
description: Ensure spec is buildable before handoff to Claude Code
---

# Spec Check â€” Design Phase

**Context:** Claude.ai design conversation
**Purpose:** Ensure spec is buildable before handoff to Claude Code
**Output:** Complete SPEC.md ready for upload

---

## When to Use

User has described a project and wants to produce a buildable spec. This command structures the validation process.

---

## Phase 1: Extract Claims

Read everything the user has provided. Extract every actionable statement.

**What is a claim?**
A claim is any statement that implies something must be built. It asserts that the product will do, show, store, compute, protect, or connect something.

**Claim Categories:**

| Category | Definition | Recognition Patterns |
|----------|------------|---------------------|
| Render | Something appears to a user | Screens, pages, components, UI elements, displays, shows, views |
| Store | Something persists beyond a session | Save, store, track, record, database, account, history, remember |
| Compute | Something transforms, calculates, or decides | Generate, calculate, if/when/then, convert, process, validate, determine |
| Protect | Something controls access or enforces rules | Only, can't, permission, role, authenticate, authorize, limit, restrict |
| Connect | Something communicates with external systems | Send, receive, integrate, API, webhook, import, export, sync, notify |

**Extraction Process:**

1. Read all provided material
2. Identify every sentence/phrase that implies building something
3. Categorize each claim
4. Note which claims reference other claims (dependencies between claims)

**Output to User:**

Present extracted claims grouped by category:
- "Here's what I understand you're building..."
- List claims with categories
- Ask: "What's missing? What's wrong?"

Iterate until user confirms claim inventory is complete.

---

## Phase 2: Expand Dependencies

For each claim, identify what must be defined to build it without guessing.

**Core Principle:** A claim is buildable when every question a developer would ask while implementing it has an answer in the spec.

### Render Claim Dependencies

When something must appear on screen, implementation requires knowing:

| Dependency Class | What Must Be Defined |
|------------------|---------------------|
| Purpose | Why does this exist? What user goal does it serve? |
| Entry | How does user arrive here? What's their mental state? |
| Content | What information/elements appear? Complete enumeration. |
| Hierarchy | What's most important? Visual weight distribution. |
| Copy | Exact text for every label, heading, message, button. |
| States | Every possible state this can be in. Not just happy path. |
| Actions | Everything user can do here. What each action causes. |
| Transitions | Where can user go from here? How do they get there? |
| Adaptation | How does this change across viewport sizes, platforms? |

**State Enumeration:**

States are not optional. Every render claim has multiple states. Common state categories:

| State Type | When It Occurs |
|------------|----------------|
| Initial | First load, before any data |
| Empty | Data exists but collection is empty |
| Loading | Waiting for async operation |
| Partial | Some data available, some pending |
| Complete | All expected data present |
| Error | Operation failed |
| Forbidden | User lacks permission |
| Stale | Data may be outdated |
| Offline | No network connectivity |

Not every state applies to every claim. Determine which states are possible for THIS claim based on what it does.

### Store Claim Dependencies

When something must persist, implementation requires knowing:

| Dependency Class | What Must Be Defined |
|------------------|---------------------|
| Entity | What conceptual thing is being stored? |
| Identity | How is one instance distinguished from another? |
| Attributes | What properties does it have? Complete enumeration. |
| Types | Data type and constraints for each attribute. |
| Optionality | Which attributes are required vs optional? |
| Defaults | What value when not specified? |
| Derivation | Which attributes are computed from others? |
| Ownership | Who does this belong to? How is ownership established? |
| Relationships | How does this connect to other stored entities? |
| Access | Who can read? Who can write? Under what conditions? |
| Lifecycle | How is it created, modified, archived, deleted? |
| Integrity | What constraints must always hold true? |

### Compute Claim Dependencies

When something must transform or decide, implementation requires knowing:

| Dependency Class | What Must Be Defined |
|------------------|---------------------|
| Trigger | What causes this computation to run? |
| Inputs | What data does it need? Where does each input come from? |
| Preconditions | What must be true for this to run? |
| Logic | The exact rules, not vague description. |
| Edge cases | What happens at boundaries? Empty inputs? Maximums? |
| Outputs | What does it produce? Where does each output go? |
| Side effects | What else changes as a result? |
| Failure modes | Every way this can fail. What happens for each. |
| Timing | Synchronous or asynchronous? Timeout limits? |
| Idempotency | What happens if run twice? |

### Protect Claim Dependencies

When something must control access, implementation requires knowing:

| Dependency Class | What Must Be Defined |
|------------------|---------------------|
| Subjects | Who/what is being granted or denied access? |
| Identity | How do we know who the subject is? |
| Authentication | How do subjects prove their identity? |
| Objects | What resources are being protected? |
| Operations | What actions are being permitted or denied? |
| Rules | The exact conditions for each subject-operation-object combination. |
| Hierarchy | Do permissions inherit? How? |
| Enforcement | Where in the system are rules enforced? |
| Violation handling | What happens when rule is broken? |
| Audit | Do we need to log access attempts? |

### Connect Claim Dependencies

When something must communicate externally, implementation requires knowing:

| Dependency Class | What Must Be Defined |
|------------------|---------------------|
| System | What external system? Specific provider, not generic category. |
| Purpose | What problem does this integration solve? |
| Direction | Data in, data out, or bidirectional? |
| Data shape | What goes over the wire? Exact structure. |
| Trigger | What causes communication to happen? |
| Authentication | How do we prove identity to external system? |
| Configuration | What settings/parameters does integration require? |
| Failure | What if external system is down, slow, or returns error? |
| Retry | What's the retry strategy? |
| Fallback | Is there degraded functionality when integration fails? |
| Rate limits | Are there usage limits? What happens when hit? |
| Cost | Does usage incur cost? |
| Testing | How to test without hitting real external system? |

---

## Phase 3: Resolve Through Conversation

For each unresolved dependency:

### Step 1: Ground in Spec Context

The user already wrote something. Connect the question to their words.

**Process:**
1. Find the exact claim in spec that created this gap
2. Quote it
3. Identify the specific part that's unresolved
4. Formulate question as delta between what they said and what's needed

The question must feel like a natural follow-up to what they wrote, not an interrogation from a template.

### Step 2: Assess Decision Type

Not all gaps are equal. Some have obvious answers. Some require real decisions.

**Determine whether reasonable default exists:**

| Factor | Default Likely Exists | User Decision Needed |
|--------|----------------------|---------------------|
| Industry practice | Strong consensus exists | No consensus or multiple valid schools |
| Reversibility | Easy to change later | Expensive to change later |
| Scope | Implementation detail | Affects user experience or business |
| Domain specificity | Common across domains | Unique to this domain/project |
| Tradeoffs | Clear winner | Genuine tradeoffs with no clear winner |

**When default exists:**
- State what it is
- Explain why it's standard (derive from domain knowledge, not assert)
- Offer to use it unless user has reason to deviate

**When no default exists:**
- Explain the decision space
- Present the genuine tradeoffs
- Let user decide with full information

### Step 3: Derive Domain-Appropriate Defaults

When offering defaults, derive them from knowledge of THIS project's domain.

**Process:**
1. Identify what domain this project is in
2. Access knowledge of how that domain typically works
3. Consider what an experienced practitioner would assume
4. Generate defaults specific to this context

Do not apply generic templates. A "user" in a B2B SaaS is different from a "user" in a consumer mobile app is different from a "user" in an internal tool. Domain context shapes reasonable defaults.

### Step 4: Surface Implications

Before accepting any decision, trace its effects.

**Causal Chain Analysis:**

For the decision being made:
- What other parts of the spec does this affect?
- What becomes required that wasn't before?
- What becomes impossible that was possible?
- What future optionality is preserved or foreclosed?
- What complexity does this add or remove?

Present non-obvious implications. Let user confirm or reconsider.

### Step 5: Batch Intelligently

**Grouping Principle:** Questions that share context should be asked together. Context includes:
- Same feature
- Same entity  
- Same screen
- Same user flow
- Same integration

**Batching Rules:**
- Never exceed working memory capacity (~5-7 questions)
- Complete one coherent area before moving to next
- When context shifts significantly, pause for user to process
- If answer to one question likely affects others, ask them together

### Step 6: Update and Verify

After receiving answer:
1. Integrate answer into evolving spec
2. Check if answer resolves other gaps (often it does)
3. Check if answer creates new gaps (sometimes it does)
4. Continue until no unresolved dependencies remain

---

## Phase 4: Scope Validation

After dependencies resolved, validate scope.

### For Projects with Users/Consumers

Test that scope is focused:

**Single-Sentence Test:**
- Attempt to explain what it does in one sentence
- If impossible without "and" or "also" â†’ scope may be too broad
- If impossible without jargon â†’ clarity may be missing

**Single-User Test:**
- Identify the one primary user type
- If "it depends" or "both X and Y" â†’ scope may be too broad
- MVP should optimize for one user, not compromise between several

**Single-Value Test:**
- Identify the one core value delivered
- If multiple distinct values â†’ may be multiple products
- Adjacent values are fine; unrelated values suggest split

### For All Projects

**One Question Filter:**

For each feature in spec, ask: "Is this required to solve the core problem for the core user?"

| Answer | Action |
|--------|--------|
| Yes, directly | Keep in MVP |
| Yes, it enables something that is | Keep in MVP |
| Yes, it prevents concrete harm | Keep in MVP |
| No, but it would be nice | Move to Deferred |
| No, and it adds complexity | Move to Not Building |

**Explicit Kill List:**

Document what you're NOT building. This prevents scope creep and clarifies boundaries.

For each killed feature:
- Why someone might want it
- Why it's not in scope

---

## Phase 5: Generate Spec

Produce SPEC.md containing all resolved information.

### Structure Principles

**Include only what exists:**
- If project has no authentication, no auth section
- If project has no external integrations, no integrations section
- If project is API-only, no screens section
- Structure reflects what's being built, not a master template

**Each section must be buildable:**
- No "[TBD]" placeholders
- No "decide later" notes
- No vague descriptions
- Everything specific enough to implement

**Organize by builder mental model:**
- Group information how a developer would need it
- Put related things together
- Make dependencies clear through ordering

### Spec Sections (Include Applicable Only)

```markdown
# [Project Name]

## Overview
[What it does, who it's for, core value â€” the grounding context]

## Scope

### Building (MVP)
[Each feature with One Question justification]

### Deferred (Post-MVP)
[Each feature with reason for deferral]

### Not Building (Kill List)
[Each excluded thing with reason]

## [Feature Sections]
[For each major feature: all resolved dependencies organized logically]

## Data Model
[All entities with complete schema â€” only if project stores data]

## Authentication & Authorization  
[Complete auth resolution â€” only if project has protected resources]

## Integrations
[Complete integration resolution â€” only if project connects externally]

## Design Direction
[Visual references, constraints, brand requirements â€” only if project has UI]

## Technical Constraints
[Platform requirements, performance targets, scale expectations â€” only if relevant]
```

---

## Completion Criteria

Spec is ready for handoff when:

1. **Claim inventory complete** â€” User confirmed all claims captured
2. **All dependencies resolved** â€” No gaps in any claim category
3. **No placeholder text** â€” Everything specific and buildable
4. **Scope explicit** â€” Clear MVP, Deferred, and Kill lists
5. **User confirmation** â€” Spec matches their intent

---

## Handoff

User downloads SPEC.md and uploads to Claude Code project.

Location options:
- Project root: `/SPEC.md`
- References folder: `/references/SPEC.md`
- Docs folder: `/docs/SPEC.md`

User then runs `/spec-check` in Claude Code for final verification before council review.
