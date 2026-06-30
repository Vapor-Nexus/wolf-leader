# Tools Arc5K runs

Arc5K runs real analyzers, then translates their output into plain English. Run
what is installed. **A missing tool just means you skip that step and say so in
the report — never block the review.**

For each tool: check it exists, run it read-only, capture output, translate.

## Database

| Tool | What it tells you | Run |
|------|-------------------|-----|
| pglinter | Schema smells: missing keys/indexes, bad types | `pglinter` against the dev DB |
| pgAssistant | Schema + query health, suggestions | per its CLI/UI |
| SchemaCrawler | Full schema dump, lint rules, diagrams | `schemacrawler --command=lint` |
| SQLFluff | SQL style/lint for views and migrations | `sqlfluff lint <dir>` |
| Postgres MCP | Live index advice, EXPLAIN, table stats | via the configured Postgres MCP server (read-only) |

Also run `scripts/profile_postgres.sql` for keys, indexes, and dead-table facts.

## ETL / data pipelines

| Tool | What it tells you | Run |
|------|-------------------|-----|
| sqlglot | Parse + column-level lineage; where a value comes from | `python` with `sqlglot` to trace lineage |

Use lineage to spot the same number derived two different ways.

## Frontend (Vue)

| Tool | What it tells you | Run |
|------|-------------------|-----|
| eslint-plugin-vue | Vue anti-patterns, logic in templates | `eslint` with the plugin |
| knip | Dead files, exports, dependencies | `knip` |
| jscpd | Copy-pasted code blocks | `jscpd <src>` |

## API

| Tool | What it tells you | Run |
|------|-------------------|-----|
| api-drift-agent | Where the API and its spec disagree | per its CLI |
| Schemathesis | Property tests from the schema (read-only, dev only) | `schemathesis run <schema-url>` against dev |

## How to check + skip

```bash
command -v jscpd >/dev/null 2>&1 && jscpd src/ || echo "jscpd not installed — skipping duplication scan"
```

In the report, keep a short "What we couldn't check" note listing skipped tools,
so the reader knows the review's blind spots.
