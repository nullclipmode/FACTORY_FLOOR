# Test-First Skill

Write failing tests BEFORE implementing code. The test defines "done".

## When to Use

- Every feature implementation
- Every bug fix
- Before any code that has acceptance criteria

## Process

### 1. Parse Acceptance Criteria

From bead or task, extract what "done" means:
```
"Add login endpoint"
→ POST /api/login with valid creds returns 200 + token
→ POST /api/login with invalid creds returns 401
→ Token is valid JWT with user ID
```

### 2. Write Failing Test First

**Unit test** (for logic):
```typescript
// tests/unit/auth.test.ts
describe('login', () => {
  it('returns token for valid credentials', async () => {
    const result = await login('test@test.com', 'password123');
    expect(result.token).toBeDefined();
    expect(result.token).toMatch(/^eyJ/); // JWT format
  });

  it('throws for invalid credentials', async () => {
    await expect(login('test@test.com', 'wrong'))
      .rejects.toThrow('Invalid credentials');
  });
});
```

**E2E test** (for integration):
```typescript
// tests/e2e/login.spec.ts
import { test, expect } from '@playwright/test';

test('login flow works', async ({ request }) => {
  const response = await request.post('/api/login', {
    data: { email: 'test@test.com', password: 'password123' }
  });
  expect(response.status()).toBe(200);
  const body = await response.json();
  expect(body.token).toBeDefined();
});

test('login rejects bad password', async ({ request }) => {
  const response = await request.post('/api/login', {
    data: { email: 'test@test.com', password: 'wrong' }
  });
  expect(response.status()).toBe(401);
});
```

### 3. Verify Tests Fail

```bash
npm test -- tests/unit/auth.test.ts
# Should FAIL - function doesn't exist yet

npx playwright test tests/e2e/login.spec.ts
# Should FAIL - endpoint doesn't exist yet
```

**If tests pass before implementation → tests are wrong.**

### 4. Implement Until Tests Pass

Write minimal code to make tests green. No more, no less.

### 5. Completion Check

```bash
npm test && npx playwright test
```

All green = done.

## Test Types by Task

| Task Type | Test Type | Example |
|-----------|-----------|---------|
| API endpoint | E2E + Unit | Playwright request + logic tests |
| UI component | E2E + Snapshot | Playwright visual + interaction |
| Bug fix | Regression test | Test that reproduces the bug |
| Refactor | Existing tests | No new tests, just don't break |
| Database change | Integration | Test with real DB |

## File Naming Convention

```
tests/
├── unit/           # Fast, isolated
│   └── {feature}.test.ts
├── e2e/            # Full integration
│   └── {feature}.spec.ts
└── fixtures/       # Test data
```

## Output

After applying this skill, output:
```
TEST FILES CREATED:
- tests/unit/auth.test.ts (3 tests)
- tests/e2e/login.spec.ts (2 tests)

INITIAL STATE: 5 tests failing (expected)

Ready to implement.
```
