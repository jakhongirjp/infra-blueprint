# Runbook: error budget burn

**Alerts:** `ErrorBudgetBurnFast` (page), `ErrorBudgetBurnSlow` (ticket).

1. Open the service dashboard and check whether errors started with a deploy:
   `argocd app history <app>`.
2. If a deploy correlates, roll back first and investigate after:
   `argocd app rollback <app> <previous-id>`.
3. Otherwise check dependencies in this order: PostgreSQL (connections,
   CPU, locks in Performance Insights), NATS, DNS (CoreDNS errors), nodes
   (`kubectl get nodes`, pending pods).
4. If the budget for the month is spent, the service owner freezes feature
   releases until it recovers, per the SLO policy.
