# Database review

Goal: find structural problems in the schema and explain them plainly.

## Gather

- Run `scripts/profile_postgres.sql` (read-only) for tables, keys, indexes, row
  counts, and dead-table signals.
- Run pglinter / SchemaCrawler lint / Postgres MCP index advice (see tools.md).

## Look for

- **Missing primary keys.** Tables with no PK — rows can't be uniquely addressed.
- **Missing foreign keys.** Columns that clearly reference another table but have
  no FK — nothing stops orphaned/garbage data.
- **Missing indexes.** Columns used in WHERE/JOIN with no index — the DB scans
  the whole table to answer.
- **Wrong/loose types.** Numbers stored as text, money as float, timestamps as
  strings.
- **Dead tables/columns.** Zero rows, never written, never read, or duplicated by
  a newer table.
- **The same fact stored twice.** Two tables/columns that must agree but nothing
  keeps them in sync.
- **Calculations baked into stored values** that should be a view instead.

## Decide

For each calculation found in the DB, confirm it belongs there (see decide.md).
Storing raw facts: good. Storing formatted/derived values that drift: flag it.

## Write each finding

Use the style in style.md. Example:

> The `orders` table has no primary key, so there's no reliable way to point at a
> single order — updates and joins can hit the wrong rows. **Recommendation:** add
> a primary key on `order_id`.

Work the [../checklists/db.md](../checklists/db.md) checklist before finishing.
