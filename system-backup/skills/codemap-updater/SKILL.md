---
name: codemap-updater
description: Updates codebase navigation map at checkpoints. Helps Claude navigate efficiently without burning context on exploration.
---

# Codemap Updater Skill

Maintain a navigation map of the codebase for efficient exploration.

## When to Use

- After completing a major feature
- After significant refactoring
- When starting a new session
- When context window is getting full

## Codemap Format

Create/update `.claude/CODEMAP.md`:

```markdown
# Codebase Map

Updated: [timestamp]

## Directory Structure

```
src/
├── components/     # React components
│   ├── ui/        # Primitive UI components
│   └── features/  # Feature-specific components
├── lib/           # Shared utilities
├── api/           # API route handlers
└── types/         # TypeScript types
```

## Key Files

| File | Purpose | Key Exports |
|------|---------|-------------|
| src/lib/auth.ts | Authentication logic | login, logout, getUser |
| src/lib/db.ts | Database connection | query, transaction |
| src/api/users.ts | User CRUD endpoints | GET, POST, PUT, DELETE |

## Entry Points

- **Web app**: src/app/page.tsx
- **API**: src/app/api/
- **Workers**: src/workers/

## Conventions

- Components: PascalCase, default export
- Utilities: camelCase, named exports
- API routes: RESTful, JSON responses

## Recent Changes

- [date]: Added user authentication
- [date]: Refactored database layer
```

## Update Process

1. **Scan for changes**: `git diff HEAD~10 --stat`
2. **Identify new files**: `git ls-files --others --exclude-standard`
3. **Update structure**: Add new directories/files
4. **Update key files**: Note new important files
5. **Update recent changes**: Add summary

## Checkpoint Triggers

Update codemap when:
- Bead closes (after commit)
- Session starts (after re-anchoring)
- Major exploration reveals new patterns
- Agent reports "lost" or "confused"

## Benefits

- **Faster navigation**: Know where things are
- **Less context burn**: Don't re-explore
- **Better decisions**: Understand architecture
- **Session continuity**: Next session has map
