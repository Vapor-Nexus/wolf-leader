# API checklist

- [ ] Responses match the documented contract (no silent drift)
- [ ] No dead endpoints (nothing calls them)
- [ ] No near-duplicate endpoints doing the same job
- [ ] No business rules living in route handlers
- [ ] The same entity has one consistent shape across endpoints
- [ ] Field naming is consistent (not customerId here, customer_id there)
- [ ] Drift/contract tools run against dev only (api-drift-agent / Schemathesis)
- [ ] Noted any tool we couldn't run (and why)
