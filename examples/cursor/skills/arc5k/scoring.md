# Scoring findings — worst first

Rank every finding so the report leads with what hurts most. Score two things
from 1-5 and multiply.

## Impact (how much it hurts)

| Score | Meaning |
|-------|---------|
| 5 | Causes wrong data or silent disagreement between numbers users trust |
| 4 | Real bug risk or noticeable slowness users feel |
| 3 | Makes changes slow/fragile (every edit risks a regression) |
| 2 | Clutter or confusion; no direct user harm |
| 1 | Cosmetic / nice-to-have |

## Effort to fix (how hard)

| Score | Meaning |
|-------|---------|
| 1 | Minutes — add an index, drop a dead table |
| 2 | An hour — extract one shared function/view |
| 3 | Half a day — reshape one area, migrate some data |
| 4 | Multi-day — restructure across layers |
| 5 | Project-level — schema redesign or rewrite |

## Priority

`priority = impact * (6 - effort)`

High impact + low effort floats to the top. Sort findings by priority, highest
first. In the report, group into:

- **Fix now** (priority >= 16) — high pain, cheap to fix.
- **Plan soon** (priority 8-15) — worth scheduling.
- **Later** (priority < 8) — track but don't rush.

Always show the worst-first order. Let `scripts/score_findings.py` do the sort
when you have findings in JSON.
