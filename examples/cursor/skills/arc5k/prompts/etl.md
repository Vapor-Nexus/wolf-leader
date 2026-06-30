# ETL / pipeline review

Goal: find duplicated or misplaced transforms and trace where numbers come from.

## Gather

- Inventory the pipeline files (`scripts/collect_inventory.sh`).
- Use sqlglot for column-level lineage: for a given output value, trace which
  source columns and expressions produced it (see tools.md).

## Look for

- **The same transform in the pipeline and the app.** A number computed in ETL
  that the backend or frontend also recomputes — they will drift.
- **Business rules hiding in load scripts.** Logic the rest of the app needs at
  runtime but that only exists in a batch job.
- **Re-derived values.** The same figure computed two different ways from the
  same source — they should share one definition.
- **Silent data loss / dedupe.** Steps that drop or merge rows in ways nobody
  documented.
- **Not safe to re-run.** A pipeline that doubles or corrupts data if run twice.

## Decide

Prefer defining shared calculations once (usually a DB view) and having ETL read
that, rather than ETL owning a formula the app also needs. See decide.md.

## Write each finding

Plain English per style.md. Example:

> The pipeline calculates the seed cost, and the quote screen calculates it again
> a slightly different way. Same input, two answers waiting to happen.
> **Recommendation:** define it once in a database view and have both read it.

Work the [../checklists/etl.md](../checklists/etl.md) checklist before finishing.
