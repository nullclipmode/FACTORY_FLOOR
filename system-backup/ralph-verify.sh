#!/bin/bash
# Ralph verification wrapper - quiet output, fail-fast
# Called by Claude during verification phase

source ~/.claude/run_silent.sh

echo "=== Verification ==="

# Lint (if script exists)
if grep -q '"lint"' package.json 2>/dev/null; then
    if ! run_silent "lint" "npm run lint 2>&1"; then
        echo "VERIFY_RESULT=FAIL:LINT"
        exit 1
    fi
fi

# Build
if ! run_silent "build" "npm run build 2>&1"; then
    echo "VERIFY_RESULT=FAIL:BUILD"
    exit 1
fi

# Tests (bail after first suite failure)
if ! run_silent "tests" "npm test -- --bail=1 2>&1"; then
    echo "VERIFY_RESULT=FAIL:TESTS"
    exit 1
fi

echo "VERIFY_RESULT=PASS"
exit 0
