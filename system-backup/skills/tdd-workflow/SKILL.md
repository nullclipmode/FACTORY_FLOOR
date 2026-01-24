---
name: tdd-workflow
description: Test-driven development workflow. Write failing tests first, then implement until tests pass.
---

# TDD Workflow Skill

Complete test-driven development cycle: write failing tests, implement, verify.

## When to Use

- All new feature implementations
- All bug fixes
- Any code with acceptance criteria

## Workflow

### Phase 1: Write Failing Tests

1. **Parse acceptance criteria** from bead or task
2. **Create test file(s)** with test cases
3. **Run tests** - they MUST fail
4. **If tests pass** - tests are wrong, rewrite

Output at end of Phase 1:
```
TEST FILES CREATED:
- tests/unit/feature.test.ts (N tests)
- tests/e2e/feature.spec.ts (M tests)

INITIAL STATE: X tests failing (expected)
```

### Phase 2: Implement

1. **Read failing tests** - understand what's needed
2. **Write minimal code** to make ONE test pass
3. **Run that test** - verify it passes
4. **Repeat** until all tests pass
5. **DO NOT modify test files** after Phase 1

Rules:
- One test at a time
- Minimal code only
- No premature optimization
- No extra features

### Phase 3: Verify

1. **Run full test suite**: `npm test`
2. **Run build**: `npm run build`
3. **Check for regressions**: compare to baseline

Output at end of Phase 3:
```
FINAL STATE: All X tests passing
BUILD: Success
REGRESSION: None detected
```

## Test File Conventions

```
tests/
├── unit/           # Fast, isolated, mock dependencies
│   └── {feature}.test.ts
├── e2e/            # Full integration, real services
│   └── {feature}.spec.ts
└── fixtures/       # Shared test data
    └── {entity}.json
```

## Test-First Checklist

Before implementation:
- [ ] Acceptance criteria extracted
- [ ] Test file created
- [ ] Tests written for happy path
- [ ] Tests written for edge cases
- [ ] Tests written for error cases
- [ ] All tests fail (verified)

After implementation:
- [ ] All new tests pass
- [ ] All existing tests pass
- [ ] No test files modified during implementation
- [ ] Build succeeds

## Anti-Patterns

**DON'T:**
- Write implementation before tests
- Modify tests to make them pass
- Skip edge case tests
- Test implementation details (test behavior)
- Add tests after implementation "for coverage"

**DO:**
- Let tests drive design
- One assertion per test (when practical)
- Test public interfaces
- Name tests descriptively: `should_do_X_when_Y`
