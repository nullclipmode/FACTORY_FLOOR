---
description: Approve a HITL bead after human review
---

# HITL Approve

Human approval for beads requiring judgment/taste decisions.

## Input

`$ARGUMENTS` should be a bead ID (e.g., `ff-abc`)

---

## Flow

### 1. Validate Bead

```bash
BEAD_ID="$ARGUMENTS"

if [ -z "$BEAD_ID" ]; then
    echo "Usage: /hitl-approve <bead-id>"
    exit 1
fi

# Check bead exists
if ! bd show "$BEAD_ID" --json > /dev/null 2>&1; then
    echo "ERROR: Bead not found: $BEAD_ID"
    exit 1
fi

# Check it's actually a HITL bead
LABELS=$(bd show "$BEAD_ID" --json | jq -r '.labels[]?')
if ! echo "$LABELS" | grep -q "^hitl$"; then
    echo "WARNING: $BEAD_ID is not a HITL bead (no hitl label)"
    echo "Use 'bd close $BEAD_ID' for regular beads"
    exit 1
fi
```

### 2. Show Bead for Review

```
═══════════════════════════════════════════════════
HITL APPROVAL: $BEAD_ID
═══════════════════════════════════════════════════

TITLE: {title}
DESCRIPTION: {description}

This bead requires human judgment. Review the work
and confirm it meets expectations.

APPROVE?
  Enter 'yes' to approve and unblock downstream tasks
  Enter 'no' to reject (will mark as blocked)
  Enter 'rework' to request changes

═══════════════════════════════════════════════════
```

### 3. Process Approval

**If approved:**
```bash
bd close "$BEAD_ID" --reason "HITL approved by human"
bd label remove "$BEAD_ID" hitl
echo "✓ Approved. Downstream tasks unblocked."

# Show what's now unblocked
UNBLOCKED=$(bd list --json | jq -r ".[] | select(.blocks[]? == \"$BEAD_ID\") | select(.status != \"done\") | .id")
if [ -n "$UNBLOCKED" ]; then
    echo ""
    echo "Now runnable:"
    for id in $UNBLOCKED; do
        TITLE=$(bd show "$id" --json | jq -r '.title')
        echo "  - $id: $TITLE"
    done
fi
```

**If rejected:**
```bash
bd update "$BEAD_ID" --status blocked
bd comments add "$BEAD_ID" "HITL rejected by human - needs rework"
echo "✗ Rejected. Bead marked as blocked."
```

**If rework:**
```bash
bd update "$BEAD_ID" --status open
bd comments add "$BEAD_ID" "HITL needs rework - returned for revision"
echo "↻ Returned for rework. Bead reopened."
```

---

## Output Format

```
═══════════════════════════════════════════════════
HITL APPROVAL: ff-abc
═══════════════════════════════════════════════════

RESULT: APPROVED | REJECTED | REWORK

DOWNSTREAM IMPACT:
  Unblocked: ff-def, ff-ghi
  Still blocked: (none)

═══════════════════════════════════════════════════
```

---

## Usage Examples

```bash
# Approve a HITL bead
/hitl-approve ff-abc

# After approval, downstream AUTO beads can run
/fix-bead --auto
```

## When to Use HITL

Create HITL beads for:
- UI/UX review (does it look right?)
- Copy/content approval (does the tone match?)
- Architecture decisions (is this the right approach?)
- Security review (is this safe?)
- Anything requiring taste or judgment

```bash
# Create HITL bead
bd create "Review dashboard layout" --label hitl

# Create dependent AUTO bead
bd create "Add dashboard API" \
  --acceptance "tests/api/dashboard.spec.ts" \
  --blocks "ff-abc"
```
