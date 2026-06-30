# Architecture Review — <App Name>

_Read-only review. Date: <YYYY-MM-DD>. Reviewed against: <local/dev>. Layers: <list>._

## The short version

<Three to five sentences a non-engineer can follow: the biggest problems, the
overall shape of the fix, and roughly how much work it is. No jargon.>

## Worst problems first

### 1. <Plain-English headline of the worst problem>

- **What's wrong:** <one or two sentences>
- **Why it matters:** <what it costs in real life — bugs, drift, slowness, time>
- **Where it lives:** <files/tables/endpoints>
- **Recommendation:** <one clear action>
- **Priority:** Fix now / Plan soon / Later (impact x effort)

### 2. <Next problem>

<same shape>

<...repeat, worst first...>

## Where calculations should live

| Calculation | Computed in (today) | Should live in | Why |
|-------------|---------------------|----------------|-----|
| <e.g. seed cost> | <ETL, backend, Vue> | <DB view> | <one source of truth> |

## What we couldn't check

<Tools that weren't installed / steps skipped, so the reader knows the blind spots.>

## See also

- Step-by-step fixes: `fix-plan.md`
- Target database shape: `db-target.md`
