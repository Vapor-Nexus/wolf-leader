# Frontend (Vue) checklist

- [ ] No business math (pricing, totals, eligibility) computed in components
- [ ] No calculation copied across multiple components
- [ ] No dead components/composables/exports/dependencies (knip)
- [ ] No heavy logic inside templates (use computed or move it down)
- [ ] Frontend isn't rebuilding shapes the API should send correctly
- [ ] Display formatting stays here; business calculations pushed down
- [ ] Copy-paste scan run (jscpd) and reviewed
- [ ] Noted any tool we couldn't run (and why)
