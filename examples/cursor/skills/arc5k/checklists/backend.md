# Backend checklist

- [ ] No business rule duplicated across services
- [ ] No row-by-row DB work that one query/view would do
- [ ] No once-per-row DB calls inside loops
- [ ] No presentation/formatting that belongs in the frontend
- [ ] Endpoints/handlers aren't doing data + rules + formatting all at once
- [ ] App-context rules stay here; pure shared calculations pushed to a view
- [ ] Copy-paste scan run (jscpd) and reviewed
- [ ] Noted any tool we couldn't run (and why)
