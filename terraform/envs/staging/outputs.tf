output "cluster_name" {
  value = module.eks.cluster_name
}

output "ledger_db_endpoint" {
  value = module.ledger_db.endpoint
}

output "nat_public_ips" {
  value = module.network.nat_public_ips
}
