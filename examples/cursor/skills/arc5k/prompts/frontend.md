# Frontend (Vue) review

Goal: find duplicated logic, dead code, and business math that snuck into the UI.

## Gather

- Run knip (dead files/exports/deps), jscpd (copy-paste), and eslint-plugin-vue
  (see tools.md).

## Look for

- **Business math in components.** Pricing, totals, eligibility calculated in a
  `.vue` file. The screen should display results, not compute them.
- **The same calculation in several components.** Copy-pasted formulas across
  screens — they drift.
- **Dead code.** Components, composables, exports, and dependencies nothing uses.
- **Logic in templates.** Heavy expressions inside the template instead of a
  computed property or the backend.
- **Reformatting server data.** The frontend rebuilding shapes the API should
  just send correctly.

## Decide

Frontend keeps display formatting and interaction only. Move business
calculations to a DB view or the backend (decide.md).

## Write each finding

Plain English per style.md. Example:

> The order total is added up inside three different screens. If the rounding
> rule changes, all three have to change, and the totals can disagree with what
> the backend thinks. **Recommendation:** have the backend send the total and let
> the screens just show it.

Work the [../checklists/frontend.md](../checklists/frontend.md) checklist before finishing.
