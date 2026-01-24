# No Self-Assessment

Agent cannot mark work DONE without external verification.

## The Problem

Agents can hallucinate success, misunderstand requirements, or game criteria. Self-reported "done" is unreliable.

## The Solution

1. **Commit gate is the oracle** - Only external verification (build, test, lint) can confirm completion
2. **No verbal assertions** - "I believe this works" is not proof
3. **Observable outcomes only** - File exists, test passes, endpoint responds
4. **Structured output required** - `<promise>DONE</promise>` or `<promise>FAILED</promise>`

## Verification Chain

```
Build claims DONE
       ↓
Verifier checks (build, test, visual)
       ↓
Reviewer checks (code quality, security)
       ↓
Commit gate enforces (all must pass)
       ↓
Only then: bead marked closed
```

## Anti-Gaming Rules

- Cannot modify test files to make them pass
- Cannot weaken acceptance criteria
- Cannot close bead without commit gate approval
- Cannot skip verification phases
