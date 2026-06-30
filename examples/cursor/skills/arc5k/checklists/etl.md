# ETL checklist

- [ ] No transform duplicated between the pipeline and the app
- [ ] No business rule that only exists in a batch job but is needed at runtime
- [ ] No value re-derived two different ways from the same source
- [ ] Steps that drop/merge rows are intentional and documented
- [ ] Pipeline is safe to run twice without doubling/corrupting data
- [ ] Shared calculations read from one definition (a view), not reimplemented
- [ ] Lineage traced for the key output numbers (sqlglot)
- [ ] Noted any tool we couldn't run (and why)
