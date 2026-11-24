# Engineering design

Architecture, security baseline, environments, DR and observability are in
the [README](../README.md); decisions in the [ADRs](adr); procedures in
[runbooks](runbooks).

## Boundaries

| Layer | Owns | Changed by |
|---|---|---|
| `terraform/bootstrap` | State bucket and its KMS key | Platform team, once per account |
| `terraform/modules/*` | Reusable building blocks: network, EKS, PostgreSQL | Platform team, versioned with the repo |
| `terraform/envs/*` | Composition and sizing per environment | Platform team, PR + plan |
| `k8s/charts/service` | The one way a service runs on the cluster | Platform team |
| `k8s/argocd/apps/*` | Which service version runs where | Service teams, PR |

## Change process

1. PR runs `fmt`, `validate`, `terraform test` per module, tflint, Trivy,
   chart policy and kubeconform.
2. If the AWS plan role is configured, CI posts `terraform plan` for both
   environments as an artifact.
3. Apply is done from a workstation or a protected workflow by the platform
   team after review. Production applies require a second approver.
4. Kubernetes changes are applied only by Argo CD.

## Testing strategy

| What | How |
|---|---|
| Module security properties | `terraform test` with `mock_provider`: e.g. cluster endpoint is private, IMDSv2 enforced, RDS private, encrypted and TLS-only, NAT per AZ in production |
| Input validation | Tests that invalid inputs (world-open API CIDR, a single AZ, a short backup window) fail at plan |
| Stack wiring | `terraform validate` for bootstrap and both envs |
| Misconfiguration | Trivy config scan, tflint with the AWS ruleset |
| Manifests | `helm lint`, `kubeconform` on rendered charts and Argo CD apps, `scripts/check_chart_policy.py` |
| Planned | Ephemeral-account apply test on a schedule (M8) |

## Cost management

Staging uses spot nodes and a single NAT gateway; production pays for per-AZ
NAT and Multi-AZ RDS because those buy the RTO in the DR table. Planned: AWS
Budgets alarms and cost allocation tags enforced by policy (M6).

## Documentation strategy

README for the whole picture, ADRs for decisions, runbooks written as steps a
tired on-call engineer can follow, and comments in Terraform only where the
*why* isn't obvious from the code.
