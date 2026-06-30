# Database checklist

- [ ] Every table has a primary key
- [ ] Reference columns have foreign keys
- [ ] Columns used in WHERE/JOIN are indexed
- [ ] Types fit the data (no money-as-float, no number-as-text, no date-as-string)
- [ ] No dead tables (zero rows / never read / replaced by a newer table)
- [ ] No dead columns (always null / never used)
- [ ] No fact stored in two places without something keeping them in sync
- [ ] Derived/formatted values aren't stored where a view would be safer
- [ ] Shared calculations exist as views, not copied into app code
- [ ] Noted any tool we couldn't run (and why)
