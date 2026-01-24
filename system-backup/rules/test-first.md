# Test-First Principle

Tests define "done". Write tests FIRST, then implement.

## Workflow

### Phase 1: Write Failing Tests
1. Write test code that verifies acceptance criteria
2. Run tests - they MUST fail (code doesn't exist yet)
3. If tests pass before implementation, something is wrong

### Phase 2: Implement
1. Write implementation to make tests pass
2. Only modify implementation files, not test files
3. Run tests after each change

### Phase 3: Verify
1. All acceptance tests pass
2. Full test suite passes (no regressions)
3. Tests are the completion oracle

## Test File Lock

After Phase 1 completes, test files are READ-ONLY:
- You can only modify: `src/`, `lib/`, `app/`, etc.
- You CANNOT modify: `tests/`, `__tests__/`, `*.spec.*`, `*.test.*`
- If tests need changes → escalate to human (HITL)
- Attempting to modify locked test files = immediate failure

This prevents "gaming" acceptance criteria by weakening tests.

## Test Coverage

- New features require tests covering happy path + edge cases
- Bug fixes require regression tests proving the fix
- Refactors must not reduce test coverage
