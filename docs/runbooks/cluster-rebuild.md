# Runbook: rebuild a cluster

**Use when** a cluster is unrecoverable, or as the quarterly DR exercise.

1. `cd terraform/envs/<env> && terraform apply -replace=module.eks.aws_eks_cluster.this`
   (or apply into a fresh account or region for a regional DR exercise).
2. Install Argo CD with Helm and apply `k8s/argocd/projects/` and `k8s/argocd/root.yaml`.
3. Argo CD restores every workload from Git. Stateless services need nothing
   else; state lives in RDS and S3, outside the cluster.
4. Record the time from step 1 to all applications healthy. The target is
   under four hours; track the trend across exercises.
