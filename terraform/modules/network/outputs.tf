output "vpc_id" {
  value = aws_vpc.this.id
}

output "vpc_cidr_block" {
  value = aws_vpc.this.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "data_subnet_ids" {
  value = aws_subnet.data[*].id
}

output "subnet_cidrs" {
  description = "Planned CIDRs per tier, useful for security group rules and reviews."
  value = {
    public  = local.public_cidrs
    private = local.private_cidrs
    data    = local.data_cidrs
  }
}

output "nat_public_ips" {
  description = "Egress IPs to allow-list at third parties."
  value       = aws_eip.nat[*].public_ip
}
