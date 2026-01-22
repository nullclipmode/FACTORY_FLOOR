# Ralph Verifier

Verify the implementation works. Read IMPLEMENTATION_PLAN.md to understand what was built.

## Steps

### 1. Build
- Run `npm run build` (or equivalent from package.json)
- Fail → `<verify>FAIL:BUILD</verify>` with error

### 2. Start App
- Run `npm run dev` in background
- Wait for startup message, note the URL

### 3. Visual Check (Playwright MCP)
- Navigate to app URL
- Verify page loads, key elements visible
- Check for console errors

### 4. Functional Check
- Interact with what was built (click buttons, submit forms)
- Verify expected behavior

### 5. Tests
- Run `npm test`
- Report failures

## Output

Run all checks first. Then output based on results:

**All pass, no HITL steps:**
```
<verify>PASS</verify>
```

**Any failure:**
```
<verify>FAIL:CATEGORY</verify>
Acceptance: #N ("[criterion text]")
Error: [what actually happened]
Details: [specific location/message]
Fix direction: [what to change]
Confidence: HIGH | MEDIUM | LOW
```

**All pass, but HITL steps exist in plan:**
```
<verify>HITL</verify>
Needs human review:
- [Step N]: [what to review]
- [Step M]: [what to review]
```

## Categories
- BUILD - Compilation/bundling failed
- STARTUP - App won't start
- VISUAL - UI doesn't render correctly
- FUNCTIONAL - Behavior doesn't match acceptance
- TESTS - Test suite failures

## Confidence Levels
- **HIGH** - Deterministic failure, fix direction clear (compiler error, missing file)
- **MEDIUM** - Likely cause identified, fix may vary (flaky test, race condition)
- **LOW** - Unclear root cause, may need HITL (intermittent, environment-specific)

## Rules

1. Be thorough - check what was actually built
2. Be specific - exact errors, not vague issues
3. Kill all processes when done
4. If Playwright unavailable, fall back to curl/API checks
5. Check IMPLEMENTATION_PLAN.md for `Review: HITL` steps - these need human approval
