# API review

Goal: find where the API and its contract disagree, and dead/duplicated endpoints.

## Gather

- Inventory routes/endpoints (`scripts/collect_inventory.sh`).
- Run api-drift-agent and/or Schemathesis against **dev only** (see tools.md).

## Look for

- **Drift from the spec.** Endpoints that return more, less, or different shapes
  than the documented contract — clients break quietly.
- **Dead endpoints.** Routes nothing calls anymore.
- **Near-duplicate endpoints.** Two routes doing almost the same thing — pick one.
- **Business logic in the controller.** Rules that belong in a service or view
  sitting directly in the route handler.
- **Inconsistent shapes.** The same entity returned differently by different
  endpoints (one sends `customerId`, another `customer_id`).

## Decide

The API layer should translate between HTTP and the backend, not own business
rules. Push rules down (decide.md).

## Write each finding

Plain English per style.md. Example:

> Two endpoints return a "customer," but one includes the address and the other
> doesn't, and they name the fields differently. The frontend has to special-case
> each one. **Recommendation:** return one consistent customer shape everywhere.

Work the [../checklists/api.md](../checklists/api.md) checklist before finishing.
