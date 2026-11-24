# Runbook: PostgreSQL point-in-time restore

**Use when** data was deleted or corrupted by a bad migration, a bug or an
operator mistake and you need the database as it was at a moment in the past.

RPO: up to 5 minutes (transaction logs are shipped every 5 minutes).
RTO: 30–60 minutes for ~100 GB, dominated by restore time.

## 1. Stop the bleeding

1. Declare an incident and name an incident commander.
2. Scale writers to zero so the damage does not grow:
   `kubectl -n ledgerflow scale deploy/ledgerd --replicas=0`
   (Argo CD self-heal will revert this; pause it first:
   `argocd app set ledgerd-production --sync-policy none`.)
3. Find the last good timestamp from application logs or the audit log. Use UTC.

## 2. Restore to a new instance

Never restore over the original; keep it for forensics.

```bash
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier acme-production-ledger \
  --target-db-instance-identifier acme-production-ledger-pitr \
  --restore-time 2026-11-24T09:41:00Z \
  --db-subnet-group-name acme-production-ledger \
  --vpc-security-group-ids <sg from terraform output> \
  --db-parameter-group-name <current parameter group> \
  --multi-az --deletion-protection
aws rds wait db-instance-available --db-instance-identifier acme-production-ledger-pitr
```

## 3. Verify

- Connect from a debug pod and check row counts and the latest records around
  the restore time.
- For ledgerflow: `SELECT sum(CASE WHEN direction='debit' THEN amount ELSE -amount END) FROM postings;`
  must be `0` (books balance).

## 4. Cut over

Either point the service at the new endpoint (update the `ledgerd-config`
secret through External Secrets) or, if only some rows were lost, copy them
back into the original with `pg_dump --data-only --table`.

## 5. Recover

1. Scale writers back up and re-enable Argo CD automated sync.
2. Import the new instance into Terraform state or rename it to the original
   identifier so Terraform keeps managing it.
3. Write the post-incident review within five working days.
