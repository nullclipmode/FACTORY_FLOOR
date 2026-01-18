---
description: Verify uploaded spec is buildable by resolving all dependencies
---

# /spec-check

**Location:** `~/.claude/commands/spec-check.md`
**Purpose:** Verify uploaded spec is buildable by resolving all dependencies
**Prerequisite:** SPEC.md exists in project

---

## When to Use

User has uploaded SPEC.md from design phase. This command validates the spec is complete enough to build without guessing.

---

## Step 1: Locate and Read Spec

Search for SPEC.md in order:
1. Project root: `/SPEC.md`
2. References: `/references/SPEC.md`
3. Docs: `/docs/SPEC.md`

**If not found:** 
"No SPEC.md found. Upload your spec from design phase, or provide the spec describing what you're building."

**If found:**
Read entire file into context. Proceed to Step 2.

---

## Step 2: Extract Claims

Parse spec into actionable claims. A claim is any statement implying something must be built.

**Claim Categories:**

| Category | Definition | What It Implies |
|----------|------------|-----------------|
| Render | Something appears to a user | Screens, components, UI elements, visual states |
| Store | Something persists beyond a session | Data structures, schemas, persistence logic |
| Compute | Something transforms or decides | Business logic, calculations, rules, validations |
| Protect | Something controls access | Authentication, authorization, permissions, limits |
| Connect | Something communicates externally | Integrations, APIs, webhooks, external services |

**Extraction Process:**

1. Read every section of the spec
2. Identify statements that assert the product will do/show/store/compute/protect/connect something
3. Categorize each claim
4. Track which claims reference other claims

**Output:** Internal list of all claims with category tags. Do not output to user yet.

---

## Step 3: Dependency Resolution

For each claim, determine if the spec contains everything needed to implement it.

### Resolution Principle

A claim is **resolved** when a developer could implement it without making assumptions, asking questions, or guessing at intent.

A claim is **unresolved** when implementation would require choosing between alternatives, inventing behavior, or making assumptions not stated in spec.

### Dependency Classes by Category

#### Render Claims

Implementation requires:

| Dependency | Resolved When | Unresolved When |
|------------|---------------|-----------------|
| Purpose | Clear why this exists | Purpose vague or missing |
| Entry | How users arrive is stated | Entry paths unclear |
| Content | All elements enumerated | "etc" or incomplete lists |
| Hierarchy | Visual priority clear | Everything same weight |
| Copy | Exact text specified | Placeholder or "[TBD]" |
| States | All possible states defined | Only happy path shown |
| Actions | Each action's outcome specified | Actions listed without outcomes |
| Transitions | Navigation paths explicit | Where users go unclear |
| Adaptation | Viewport behavior stated | Only one size considered |

**State Resolution:**

For each render claim, verify these states are addressed (where applicable):

| State | Addressed When |
|-------|----------------|
| Empty | Spec says what shows when no data exists |
| Loading | Spec says what shows during async operations |
| Error | Spec says what shows on failure, including message content |
| Success | Spec says what shows on successful operations |
| Partial | Spec says what shows when some data missing |
| Forbidden | Spec says what shows when access denied |

Not all states apply to all claims. Determine which are possible for THIS claim, then check if those are addressed.

#### Store Claims

Implementation requires:

| Dependency | Resolved When | Unresolved When |
|------------|---------------|-----------------|
| Entity definition | Clear what conceptual thing this is | Entity vague or overloaded |
| Identity | Primary key / unique identifier specified | No way to distinguish instances |
| Attributes | All fields listed | Incomplete or "and more" |
| Types | Data type for each attribute | Types unspecified or vague |
| Constraints | Required/optional, min/max, format specified | Constraints unclear |
| Defaults | Default values stated | No mention of defaults |
| Ownership | Who owns this data is clear | Ownership ambiguous |
| Relationships | Connections to other entities defined | References without definition |
| Access rules | Who can read/write explicitly stated | Access control vague |
| Lifecycle | Create/update/delete behavior specified | Only creation mentioned |

#### Compute Claims

Implementation requires:

| Dependency | Resolved When | Unresolved When |
|------------|---------------|-----------------|
| Trigger | What initiates computation is clear | Trigger ambiguous |
| Inputs | All inputs identified with sources | Inputs vague or partial |
| Preconditions | What must be true before running | Assumptions unstated |
| Logic | Exact rules, not descriptions | Vague like "handles appropriately" |
| Edge cases | Boundary behavior specified | Only typical case covered |
| Outputs | What's produced and where it goes | Output unclear |
| Side effects | Other changes documented | Hidden effects possible |
| Failure handling | What happens when fails | Failure not addressed |

#### Protect Claims

Implementation requires:

| Dependency | Resolved When | Unresolved When |
|------------|---------------|-----------------|
| Auth method | Specific method chosen | "authentication" without method |
| Identity establishment | How users prove identity | Method vague |
| Subjects | Who/what gets access | Vague like "users" |
| Objects | What's being protected | Resources not enumerated |
| Operations | What actions are permitted/denied | Actions not listed |
| Rules | Exact conditions for each case | Vague like "appropriate access" |
| Enforcement | Where rules are enforced | Enforcement unclear |
| Violation handling | What happens on rule break | Violations not addressed |

#### Connect Claims

Implementation requires:

| Dependency | Resolved When | Unresolved When |
|------------|---------------|-----------------|
| Provider | Specific service named | Generic category only |
| Purpose | What integration accomplishes | Vague purpose |
| Data shape | What goes over wire | Data structure unclear |
| Trigger | When communication happens | Trigger not specified |
| Authentication | How we auth to external system | Auth method unclear |
| Failure handling | What if external system fails | Failure not addressed |
| Fallback | Degraded mode specified | No fallback mentioned |

---

## Step 4: Cross-Reference Check

Beyond individual claims, check for coherence across spec.

**Orphan Detection:**

| Check | Problem | Question |
|-------|---------|----------|
| Orphan screens | Screen exists but no way to reach it | How does user get to [screen]? |
| Orphan data | Entity defined but never read or written | What uses [entity]? |
| Orphan features | Feature described but no screen shows it | Where does [feature] appear? |
| Forward references | Claim references undefined thing | What is [undefined thing]? |
| Circular dependencies | A requires B requires A | Which comes first? |

**Consistency Check:**

| Check | Problem | Question |
|-------|---------|----------|
| Naming conflicts | Same name, different meanings | Is [X] in context A the same as [X] in context B? |
| Permission contradictions | Conflicting access rules | Can [subject] do [action] or not? |
| State conflicts | Incompatible states possible | Can [state A] and [state B] occur together? |

---

## Step 5: Generate Output

### If All Dependencies Resolved

**First:** Check if SPEC_GAPS.md exists. If it does, update it to show resolved status:

```markdown
# Spec Gaps: [Project Name]

**Status:** âœ“ All gaps resolved
**Checked:** [timestamp]

No unresolved dependencies. Spec is buildable.
```

**Then output:**

```markdown
# Spec Check: PASSED âœ“

All dependencies resolved. Spec is buildable.

## Claim Summary

| Category | Claims | Status |
|----------|--------|--------|
| Render | [n] | âœ“ All resolved |
| Store | [n] | âœ“ All resolved |
| Compute | [n] | âœ“ All resolved |
| Protect | [n] | âœ“ All resolved |
| Connect | [n] | âœ“ All resolved |

## Ready For

`/council-review` â€” Expert council review before build
```

### If Gaps Found

Create or update `SPEC_GAPS.md`:

```markdown
# Spec Gaps: [Project Name]

**Status:** âœ— Gaps found â€” spec not yet buildable
**Generated:** [timestamp]

---

## Summary

| Category | Claims | Resolved | Gaps |
|----------|--------|----------|------|
| Render | [n] | [n] | [n] |
| Store | [n] | [n] | [n] |
| Compute | [n] | [n] | [n] |
| Protect | [n] | [n] | [n] |
| Connect | [n] | [n] | [n] |

**Total gaps:** [n]

---

## Gaps Detail

[For each claim with gaps:]

### [Claim Category]: [Claim summary]

**Spec states:** 
> "[exact quote from spec]"

**Unresolved dependencies:**

**1. [Dependency class]**
- What's missing: [specific thing not defined]
- Why it's needed: [what breaks without it]
- Question: [specific question to resolve this]

**2. [Dependency class]**
- What's missing: [specific thing not defined]
- Why it's needed: [what breaks without it]
- Question: [specific question to resolve this]

[Continue for each dependency gap in this claim]

---

[Repeat for each claim with gaps]

---

## Cross-Reference Issues

[If any found:]

### [Issue type]

- Problem: [what's inconsistent or orphaned]
- Location: [where in spec]
- Resolution needed: [what decision or clarification]

---

## Resolution Options

1. **Resolve here:** Answer the questions above, I'll update SPEC.md
2. **Return to design:** Take SPEC_GAPS.md back to Claude.ai for deeper discussion
3. **Proceed anyway:** Run `/council-review` accepting that council will flag these same gaps

Recommended: Resolve all gaps before council review.
```

---

## Step 6: Interactive Resolution (If User Chooses)

If user wants to resolve gaps in Claude Code:

**Process:**

1. Present first gap with full context
2. Assess decision type (determine if reasonable default exists)
3. Either offer default with rationale, or present decision space
4. Receive answer
5. Validate answer resolves the gap
6. Update SPEC.md with resolved information
7. Check if this answer resolves other gaps or creates new ones
8. Continue to next unresolved gap
9. When all resolved, re-run full dependency check
10. Update SPEC_GAPS.md to show "âœ“ All gaps resolved"
11. Output "Spec Check: PASSED" when clean

**Assessing Decision Type:**

For each gap, determine whether a reasonable default exists:

| If This Is True | Then |
|-----------------|------|
| Strong industry consensus exists | Offer consensus as default |
| Decision is easily reversible | Can offer default |
| Decision is implementation detail, not UX/business | Can offer default |
| Decision is common across project types | Can offer default |
| No clear winner, genuine tradeoffs | Present options, let user decide |
| Decision affects user experience | User must decide |
| Decision has business implications | User must decide |
| Decision is expensive to reverse | User must decide |

**Deriving Domain-Appropriate Defaults:**

When offering defaults:
1. Identify the domain of this project
2. Consider what's standard in that domain
3. Consider what an experienced practitioner would assume
4. Generate defaults specific to this project's context

Do not apply generic templates. Defaults must be derived from domain understanding.

**Surfacing Implications:**

Before accepting any decision:
1. Trace what other parts of spec this affects
2. Identify what becomes required as a result
3. Identify what becomes impossible as a result
4. Present non-obvious implications
5. Let user confirm or reconsider

---

## Integration

### Upstream
- Receives SPEC.md from Claude.ai design phase
- User uploads to project before running

### Downstream  
- Must pass before `/council-review` runs
- Council checks SPEC_GAPS.md status in Phase 0
- Council assumes spec is buildable if status shows resolved

### Status Values

SPEC_GAPS.md status line determines pipeline flow:

| Status | Meaning | Council Review |
|--------|---------|----------------|
| `âœ— Gaps found` | Unresolved dependencies | Blocked |
| `âœ“ All gaps resolved` | Was gaps, now fixed | Allowed |
| File doesn't exist | Never had gaps | Allowed |

---

## Command Syntax

```
/spec-check              # Check spec, output gaps or pass
/spec-check --resolve    # Check and interactively resolve gaps
/spec-check --force      # Skip check, proceed to council (not recommended)
```
