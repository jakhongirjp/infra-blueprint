# ADR-0002: GitOps for workloads, reviewed applies for infrastructure

- Status: accepted
- Date: 2026-11-24

## Decision

- **Workloads** (Helm releases of services) are reconciled by Argo CD from
  `main` with pruning and self-heal. Image tags are bumped by each service's
  release pipeline through a pull request to this repository.
- **Infrastructure** (Terraform) is planned automatically on every pull
  request through a read-only OIDC role and applied by the platform team from
  `main` with an apply role that requires approval in a protected GitHub
  environment.

## Why

Workload changes are frequent, low blast radius and easy to roll back, so
continuous reconciliation is the right default. Infrastructure changes are
rare and can be destructive (a replaced database), so a human reads the plan
before it runs.

## Consequences

- `kubectl edit` in production is reverted by self-heal; drift cannot
  accumulate.
- An AppProject restricts workloads to their own namespaces and forbids
  cluster-scoped resources; a sync window enforces the Friday change freeze.
