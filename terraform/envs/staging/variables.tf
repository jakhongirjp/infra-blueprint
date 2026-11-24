variable "operator_cidrs" {
  description = "Office/VPN egress CIDRs allowed to reach the Kubernetes API."
  type        = list(string)
  default     = []
}

variable "admin_role_arns" {
  description = "SSO roles that receive cluster-admin."
  type        = list(string)
  default     = []
}
