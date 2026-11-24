variable "name" {
  description = "Prefix for every resource name, e.g. \"acme-production\"."
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR. A /16 leaves room for three tiers across up to four AZs."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && tonumber(split("/", var.cidr_block)[1]) <= 18
    error_message = "cidr_block must be a valid IPv4 CIDR of /18 or larger."
  }
}

variable "availability_zones" {
  description = "AZs to spread subnets across. Use at least two; three for production."
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2 && length(var.availability_zones) <= 4
    error_message = "Provide between two and four availability zones."
  }
}

variable "single_nat_gateway" {
  description = "One shared NAT gateway (cheaper, single-AZ egress) instead of one per AZ."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for VPC flow logs."
  type        = number
  default     = 90
}

variable "cluster_name" {
  description = "EKS cluster name used for subnet discovery tags."
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
