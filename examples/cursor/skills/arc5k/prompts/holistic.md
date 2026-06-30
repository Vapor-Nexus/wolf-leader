# Holistic review (all layers)

This is the default mode. Review every layer, but spend most of your energy on
the thing single-layer reviews miss: **the same logic spread across layers.**

## Order of work

1. Run each layer prompt: [db.md](db.md), [etl.md](etl.md),
   [backend.md](backend.md), [api.md](api.md), [frontend.md](frontend.md).
2. Then do the cross-layer pass below.

## Cross-layer pass (the main event)

For each important calculation or rule in the app (costs, totals, discounts,
eligibility, statuses), trace it through every layer and ask:

- **How many places compute it?** If more than one, that's a finding. Use
  sqlglot lineage (ETL/DB) + jscpd (backend/frontend) to find the copies.
- **Where should it live?** Decide its one true home with [decide.md](decide.md).
- **What's the cost of it drifting?** Put that in the finding (style.md).

Build a small table while you work:

| Calculation | Computed in | Should live in | Drift risk |
|-------------|-------------|----------------|------------|
| seed cost | ETL, backend, Vue | DB view | numbers disagree on quotes |

## Then

- Rank everything worst-first with [scoring.md](scoring.md).
- Write `report.md`, `fix-plan.md`, and `db-target.md` from
  [../templates/](../templates/) into `docs/arch-review/<date>/`.

The headline of a holistic review is usually: "here are the N calculations that
live in more than one place, and here's the single home each should have."
