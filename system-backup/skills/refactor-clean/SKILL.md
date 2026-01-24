---
name: refactor-clean
description: Dead code removal and post-feature housekeeping. Cleans up loose files, unused exports, and technical debt.
---

# Refactor Clean Skill

Post-feature housekeeping: remove dead code, clean loose files, reduce tech debt.

## When to Use

- After major feature completion
- When codebase feels cluttered
- Before releases
- When lint/build warnings pile up

## Cleanup Checklist

### 1. Dead Code Removal

```bash
# Find unused exports (TypeScript)
npx ts-prune

# Find unused dependencies
npx depcheck

# Find unused files
npx unimported
```

Remove:
- [ ] Unused functions and classes
- [ ] Unused exports
- [ ] Unused dependencies in package.json
- [ ] Orphaned files (no imports)
- [ ] Commented-out code blocks

### 2. Loose Markdown Files

Audit markdown files:
```bash
find . -name "*.md" -not -path "./node_modules/*" | xargs wc -l | sort -n
```

Remove:
- [ ] Outdated documentation
- [ ] Empty or stub files
- [ ] Duplicate docs
- [ ] Development notes (move to issues)

Keep:
- README.md (root and key directories)
- CLAUDE.md (project context)
- CHANGELOG.md (if used)
- LICENSE

### 3. Console.log Cleanup

```bash
git grep "console\.log" -- "*.ts" "*.tsx" "*.js" "*.jsx"
```

Remove:
- [ ] Debug console.logs
- [ ] Commented console.logs
- [ ] TODO: remove console.logs

Keep:
- Intentional logging (logger.info, etc.)
- Error logging (console.error for unhandled)

### 4. Import Cleanup

```bash
# Sort and organize imports
npx eslint --fix --rule 'import/order: error'

# Remove unused imports
npx eslint --fix --rule 'unused-imports/no-unused-imports: error'
```

### 5. Type Cleanup

```bash
# Find any types
git grep ": any" -- "*.ts" "*.tsx"

# Find unused type exports
npx ts-prune
```

Fix:
- [ ] Replace `any` with proper types
- [ ] Remove unused type definitions
- [ ] Remove redundant type assertions

## Verification

After cleanup:
```bash
npm run typecheck  # No errors
npm run lint       # No warnings
npm run test       # All pass
npm run build      # Succeeds
```

## Output

```
CLEANUP SUMMARY:
- Removed X unused exports
- Removed Y dead files
- Removed Z console.logs
- Fixed N type errors

FILES DELETED:
- src/old-feature.ts
- docs/outdated.md

BUILD: Success
TESTS: Passing
```

## Safety Rules

1. **Never delete test files** (even if "unused")
2. **Check git history** before deleting
3. **Run tests after each major deletion**
4. **Commit incrementally** (one type of cleanup per commit)
5. **Keep types** that are used by external consumers
