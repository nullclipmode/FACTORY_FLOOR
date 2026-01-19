#!/bin/bash
# ci-bead-hook.sh - CI/CD hook to capture failures as beads
#
# Add to your CI/CD pipeline (GitHub Actions, etc.):
#
# - name: Capture build failure
#   if: failure()
#   run: ~/.claude/scripts/ci-bead-hook.sh build "${{ github.job }}" "${{ github.run_id }}"
#
# Environment variables:
#   AUTO_FIX=true   - Add auto-fix label for automated processing
#   BD_PREFIX=app   - Use specific beads prefix (for multi-app)

set -euo pipefail

BD="${HOME}/.local/bin/bd"
CAPTURE="${HOME}/.claude/scripts/bead-capture.sh"

TYPE="${1:-build}"
JOB_NAME="${2:-unknown}"
RUN_ID="${3:-}"
ERROR_LOG="${4:-}"

# Generate title and description
case "$TYPE" in
    build)
        TITLE="Build failure: $JOB_NAME"
        DESCRIPTION="CI build failed in job '$JOB_NAME'"
        ;;
    test)
        TITLE="Test failure: $JOB_NAME"
        DESCRIPTION="CI tests failed in job '$JOB_NAME'"
        ;;
    lint)
        TITLE="Lint failure: $JOB_NAME"
        DESCRIPTION="CI linting failed in job '$JOB_NAME'"
        ;;
    deploy)
        TITLE="Deploy failure: $JOB_NAME"
        DESCRIPTION="CI deployment failed in job '$JOB_NAME'"
        ;;
    *)
        TITLE="CI failure: $JOB_NAME"
        DESCRIPTION="CI failed in job '$JOB_NAME'"
        ;;
esac

# Add run ID if available
if [ -n "$RUN_ID" ]; then
    DESCRIPTION="$DESCRIPTION\n\nRun ID: $RUN_ID"
fi

# Add error log snippet if available
if [ -n "$ERROR_LOG" ] && [ -f "$ERROR_LOG" ]; then
    LOG_SNIPPET=$(tail -50 "$ERROR_LOG" 2>/dev/null || echo "")
    if [ -n "$LOG_SNIPPET" ]; then
        DESCRIPTION="$DESCRIPTION\n\n## Error Log\n\`\`\`\n$LOG_SNIPPET\n\`\`\`"
    fi
fi

# Call bead-capture
"$CAPTURE" "$TYPE" "$TITLE" "$DESCRIPTION"
