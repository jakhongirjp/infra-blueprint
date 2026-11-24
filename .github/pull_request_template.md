## What and why

<!-- The problem this solves and the approach. Link the issue: Closes #123 -->

## How it was verified

- [ ] `terraform fmt -check -recursive && terraform test (per module) && tflint --recursive` passes locally
- [ ] New behaviour is covered by tests that fail without the change

## Risk

- [ ] No schema, API or config change, **or** the migration and rollback are described below
- [ ] No new secret, permission or network path, **or** the security impact is described below
- [ ] Docs, ADRs and CHANGELOG updated where behaviour changed
