# Arc5K writing style — plain English

Findings must read like a colleague explaining the problem at a whiteboard, not
like a linter dumping rule codes. A non-engineer should follow every line.

## The shape of every finding

1. **Lead with the point.** One sentence: what's wrong, in human terms.
2. **The why, in business terms.** What it costs: bugs, drift, slowness, wasted
   time, risk. Not "violates DRY" — say what actually goes wrong.
3. **One recommendation.** A single clear "do this." Not a menu of options.

Keep it short. If a term needs a glossary, replace the term.

## Words to avoid (and what to say instead)

| Don't write | Write instead |
|-------------|---------------|
| "DRY violation" | "the same logic is copied in N places" |
| "denormalized" | "the same fact is stored in two tables, so they can disagree" |
| "N+1 query" | "it hits the database once per row instead of once total" |
| "missing covering index" | "the database has to scan the whole table to answer this" |
| "tight coupling" | "changing X forces you to change Y" |
| "idempotent" | "safe to run twice without doubling the data" |

## One before/after example

**Bad (linter voice):**

> DRY violation: duplicated `seed_cost = qty * rate * waste_factor` expression
> across `etl/transform.py`, `services/pricing.py`, and `QuoteForm.vue`.
> Recommend extracting to a shared utility.

**Good (Arc5K voice):**

> The seed-cost formula lives in 3 places — the data pipeline, the backend, and
> the quote screen. So when a rate changes, someone has to remember to fix it in
> all 3, and the day they miss one, the numbers quietly disagree.
> **Recommendation:** keep this formula in one database view and have the backend
> and the Vue screen read that, so there's a single source of truth.

Notice: the good version says *what breaks in real life* (numbers quietly
disagree) and gives *one* recommendation with a reason.
