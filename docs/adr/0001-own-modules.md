# ADR-0001: Plain AWS resources instead of community modules

- Status: accepted
- Date: 2026-11-24

## Context

Community modules (`terraform-aws-modules/vpc`, `/eks`) are excellent but
expose hundreds of inputs to serve every use case. Reviewers have to trust
defaults they cannot see, and upgrades of the module can change resources.

## Decision

Write three small modules with only the inputs this platform needs and
opinionated, secure defaults. Guardrails are input validations
(`0.0.0.0/0` API access, backup retention, scaling bounds) and preconditions
(subnet overlap), and they are covered by `terraform test` with mocked
providers.

## Consequences

- Every resource is visible in roughly 600 lines of HCL; a reviewer can read
  the whole platform in one sitting.
- We own upgrades. New EKS or RDS features need a module change.
- The modules are not a general-purpose library and are not intended to be.
