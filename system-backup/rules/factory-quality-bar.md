# Factory Quality Bar

Production-quality code requirements for all Factory Floor projects.

## Code Standards

1. **No placeholder implementations** - Every function must be fully implemented
2. **Complete error handling** - All error paths must be handled explicitly
3. **No silent failures** - Errors must be logged or surfaced, never swallowed
4. **Resolve all TODOs** - No TODO comments in committed code
5. **Code compiles** - No syntax errors, type errors, or broken imports

## Verification Gates

All must pass before commit:
- `npm run typecheck` (if present)
- `npm run lint` (if present)
- `npm run test` (if present)
- `npm run build` (if present)

## Behavior Changes

Any behavior change must include corresponding test updates:
- New feature → new tests
- Bug fix → regression test
- Refactor → existing tests still pass

## Code Review Checklist

- Logic errors, off-by-one, null checks, edge cases
- Security: injection, XSS, auth issues, secrets in code
- Missed requirements: does it do what was asked?
- Readability: naming, unnecessary complexity
