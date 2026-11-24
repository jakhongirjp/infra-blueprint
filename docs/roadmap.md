# Roadmap

Open work is tracked as [GitHub issues](https://github.com/jakhongirjp/infra-blueprint/issues)
under these milestones.

| # | Milestone | Outcome | Status |
|---|---|---|---|
| M1 | Foundations | Bootstrap, network, EKS and PostgreSQL modules with tests | Done (v0.1) |
| M2 | Delivery | Hardened service chart, Argo CD app-of-apps, SLO alerts, runbooks | Done (v0.1) |
| M3 | Disaster recovery | Cross-region backup replication, restore drill automation | Planned |
| M4 | Cluster add-ons | Karpenter, AWS Load Balancer Controller, external-dns, cert-manager as Argo apps | Planned |
| M5 | Secrets | External Secrets Operator wired to Secrets Manager | Planned |
| M6 | Cost and governance | Budgets, mandatory tags, policy-as-code for Terraform plans | Planned |
| M7 | Observability stack | kube-prometheus-stack, Loki, Grafana dashboards as code | Planned |
| M8 | Continuous verification | Scheduled apply/destroy in a sandbox account, drift detection | Planned |
| M9 | Supply chain | Signed images, admission policy that verifies signatures | Planned |
| M10 | 1.0 | Versioned module releases with upgrade notes | Planned |

## Release plan

| Version | Contents |
|---|---|
| v0.1 | M1 and M2 |
| v0.2 | M3 and M5 |
| v0.3 | M4 and M7 |
| v0.4 | M6 and M8 |
| v0.5 | M9 |
| v1.0 | M10 |
