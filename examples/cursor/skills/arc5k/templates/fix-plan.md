# Fix Plan — <App Name>

A phased, do-this-then-that list. Each phase leaves the app working. Start at the
top. Nothing here changes production automatically — these are changes for a
human (or agent) to make and review.

## Phase 1 — Quick wins (high pain, low effort)

- [ ] <e.g. Add a primary key on `orders.order_id`>
- [ ] <e.g. Add an index on `invoices.customer_id`>
- [ ] <e.g. Drop the dead `temp_import_2019` table>

_Why first:_ <one line — these are cheap and remove real risk.>

## Phase 2 — Single source of truth (stop the drift)

- [ ] <e.g. Create a `seed_cost` view in the database>
- [ ] <e.g. Point the backend pricing service at the view>
- [ ] <e.g. Remove the duplicate formula from `QuoteForm.vue`>

_Why:_ <one line — collapse copied logic into one home.>

## Phase 3 — Right layer (move logic where it belongs)

- [ ] <e.g. Move the total calculation out of the Vue screens into the backend>
- [ ] <e.g. Replace row-by-row lookups with one query>

## Phase 4 — Bigger structural work (schedule it)

- [ ] <e.g. Reshape the `customer` tables; migrate data>

_Note:_ each box should be small enough to do and verify on its own. Reference the
matching finding number in `report.md`.
