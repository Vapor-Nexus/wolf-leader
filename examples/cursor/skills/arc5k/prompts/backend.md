# Backend review

Goal: find duplicated business logic and logic that's in the wrong layer.

## Gather

- Inventory services/modules (`scripts/collect_inventory.sh`).
- Run a copy-paste detector (jscpd) across the backend source (see tools.md).

## Look for

- **Duplicated business rules.** The same calculation/validation in several
  services — change one, forget the others.
- **Logic that belongs lower.** Aggregations/joins done in app code row-by-row
  that a single DB query or view would do correctly and faster.
- **Logic that belongs higher.** Presentation/formatting done in the backend that
  is really the frontend's job.
- **Fat endpoints.** Handlers doing data access + business rules + formatting all
  in one place.
- **Once-per-row database calls.** Code hitting the DB inside a loop instead of
  once for the whole set.

## Decide

For each rule, confirm its home with decide.md: app-context rules stay in the
backend; shared pure calculations go to a DB view; display goes to the frontend.

## Write each finding

Plain English per style.md. Example:

> The discount rule is written out in three services. Today they agree; the first
> time someone updates only two of them, customers get different prices depending
> on which screen they came from. **Recommendation:** put the rule in one place
> the others call.

Work the [../checklists/backend.md](../checklists/backend.md) checklist before finishing.
