---
description: Add a lesson learned to CLAUDE.md so Claude won't repeat the mistake
allowed-tools: Bash, Read, Write, Edit
---

# Add Rule from Mistake

The user noticed Claude did something incorrectly. Your job:

1. Ask: "What did I do wrong?"
2. Ask: "What should I do instead?"
3. Format as a clear rule
4. Add to the project's `CLAUDE.md` under a "## Learned Rules" section (create if missing)
5. Commit with message: "Add learned rule: [brief summary]"
6. Confirm: "Added rule. I won't make this mistake again in this project."

Keep rules concise and actionable. Example format:
- ❌ Don't: [what was wrong]
- ✅ Do: [what to do instead]
