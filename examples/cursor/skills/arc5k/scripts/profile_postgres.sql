-- Arc5K Postgres profiler — READ-ONLY.
-- Gathers schema facts for an architecture review. Runs only SELECTs against
-- catalogs and stats views. Safe on dev. DO NOT run against production.
--
-- Usage (dev only):
--   psql "$DEV_DATABASE_URL" -f profile_postgres.sql
-- or paste sections into a read-only Postgres MCP.

\echo '== Tables without a primary key =='
SELECT n.nspname AS schema, c.relname AS table
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
    SELECT 1 FROM pg_constraint k
    WHERE k.conrelid = c.oid AND k.contype = 'p'
  )
ORDER BY 1, 2;

\echo '== Foreign-key-looking columns WITHOUT a foreign key =='
-- Columns named like *_id that have no FK constraint (candidate missing FKs).
SELECT n.nspname AS schema, c.relname AS table, a.attname AS column
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'r'
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND a.attnum > 0 AND NOT a.attisdropped
  AND a.attname LIKE '%\_id'
  AND NOT EXISTS (
    SELECT 1 FROM pg_constraint k
    WHERE k.conrelid = c.oid AND k.contype = 'f' AND a.attnum = ANY (k.conkey)
  )
ORDER BY 1, 2, 3;

\echo '== Indexes per table =='
SELECT schemaname AS schema, relname AS table, indexrelname AS index, idx_scan AS times_used
FROM pg_stat_user_indexes
ORDER BY schemaname, relname, idx_scan;

\echo '== Possible dead tables (never read, no writes, low/zero rows) =='
SELECT schemaname AS schema, relname AS table,
       n_live_tup AS rows,
       seq_scan, idx_scan,
       n_tup_ins AS inserts, n_tup_upd AS updates, n_tup_del AS deletes
FROM pg_stat_user_tables
ORDER BY (COALESCE(seq_scan,0) + COALESCE(idx_scan,0)) ASC, n_live_tup ASC;

\echo '== Largest tables that are sequentially scanned a lot (index candidates) =='
SELECT schemaname AS schema, relname AS table,
       seq_scan, seq_tup_read, idx_scan, n_live_tup AS rows
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 25;

\echo '== Columns stored as text that look numeric/temporal (type smells) =='
SELECT table_schema AS schema, table_name AS table, column_name AS column, data_type
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
  AND data_type IN ('text', 'character varying', 'character')
  AND (column_name ~* '(amount|price|cost|qty|quantity|total|count|num)'
       OR column_name ~* '(date|time|_at$|timestamp)')
ORDER BY 1, 2, 3;

\echo '== Views (existing shared calculations) =='
SELECT table_schema AS schema, table_name AS view
FROM information_schema.views
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY 1, 2;
