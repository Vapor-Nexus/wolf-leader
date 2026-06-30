# Target Database Shape — <App Name>

A clear picture of how the database should be structured. This is the destination,
not a migration script. Keep it short and readable.

## Core tables (the nouns)

| Table | Holds | Key | Links to |
|-------|-------|-----|----------|
| <customers> | <one row per customer> | <customer_id> | <—> |
| <orders> | <one row per order> | <order_id> | <customer_id → customers> |

_Rule of thumb:_ one table per real-world thing, each row uniquely identified,
each link backed by a foreign key.

## Shared calculations (views)

| View | Computes | Reads from | Who uses it |
|------|----------|------------|-------------|
| <v_seed_cost> | <seed cost per line> | <orders, rates> | <backend, Vue> |

_Rule of thumb:_ any number more than one place needs lives in a view, computed
once.

## What stores raw facts vs. derived values

- **Tables store raw facts** (quantities, rates, timestamps) — never formatted
  strings, never values that can be recomputed.
- **Views compute derived values** (totals, costs) so they can't drift.

## What to retire

- <dead tables/columns to drop, with a one-line reason each>

## Picture

```
customers ──< orders ──< order_lines
                              │
                         v_seed_cost (view)
```

_(Adjust the diagram to the real shape.)_
