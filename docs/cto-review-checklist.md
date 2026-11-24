# CTO review checklist

Where the platform stands. Unchecked items have an issue.

## Security
- [x] No static cloud credentials in CI (OIDC)
- [x] State encrypted with a customer-managed key, versioned, locked
- [x] Private cluster endpoint; open CIDRs rejected by validation
- [x] Workload hardening enforced by the chart and checked in CI
- [x] Database: TLS enforced, KMS at rest, managed master password
- [ ] Secrets delivered by External Secrets, not hand-made Kubernetes Secrets (M5)
- [ ] Image signature verification at admission (M9)

## Reliability
- [x] Multi-AZ production, per-AZ NAT, PDBs and topology spread
- [x] SLO burn-rate alerts
- [x] Runbooks for restore, budget burn and cluster rebuild
- [ ] Cross-region backup replication (M3)
- [ ] Restore drill run on a schedule (M3)

## Change management
- [x] Every module tested in CI without cloud access
- [x] Plans attached to PRs when the role is configured
- [x] GitOps for all cluster changes
- [ ] Drift detection (M8)
- [ ] Policy-as-code on plans (M6)

## Cost
- [x] Environment sizing documented, spot for staging
- [ ] Budgets and alerts (M6)
- [ ] Tag policy enforced (M6)
