# Where should this logic live?

For every calculation or rule you find, say where it *belongs* and why, in one
line. Use this guide to make the call.

## The default ranking

Push logic **down** to the lowest layer that can own it cleanly. Lower layers are
shared by everything above them, so a rule defined once there can't drift.

```
Database (table constraints / generated columns)
  └─ Database VIEW (shared read-only calculations)
       └─ Backend service (business rules, orchestration, anything needing app context)
            └─ Frontend (display formatting and interaction only)
```

## Quick decision table

| The logic is… | It belongs in… | Why |
|---------------|----------------|-----|
| A fact that must always hold (non-null, unique, valid range) | DB constraint | The database enforces it for every writer, forever |
| A calculation many places read the same way (totals, costs, rollups) | DB view | One definition everyone reads; can't drift |
| A rule that needs app context (user, permissions, external calls, workflow) | Backend | Needs things the DB doesn't have |
| Anything about how it looks (currency symbols, date format, colors, sorting for display) | Frontend | Pure presentation; no business meaning |
| A heavy transform run once on load | ETL — but defined from the same view if possible | Avoid re-deriving the same number two ways |

## Red flags

- **Same number computed in two layers** → pick one home (usually a DB view) and
  have the others read it.
- **Business math in the frontend** → move it back; the screen should display,
  not decide.
- **Display formatting in the database** → move it up; the DB should store raw
  facts, not formatted strings.
- **A rule in ETL that the app also needs at runtime** → it probably belongs in a
  view or the backend so both share it.

State the call as one line, e.g.: *"This belongs in a DB view — the backend and
the Vue screen should both read it instead of each doing the math."*
