---
description: Create database migration with up/down and type generation
---

# Database Migration

Create a reversible database migration.

## Steps

1. Create migration file with timestamp
2. Define up migration (create table, add column, etc.)
3. Define down migration (exact reversal of up)
4. Run migration locally
5. Verify schema has expected structure
6. Regenerate TypeScript types from schema

## Output

Migration file with:
- Descriptive name
- Valid SQL/migration syntax
- Reversible down migration
- Updated TypeScript types
