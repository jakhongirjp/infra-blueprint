variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Data-tier subnets (no internet route)."
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to connect on 5432, typically the EKS node/cluster SG."
  type        = list(string)
}

variable "engine_version" {
  type    = string
  default = "17.6"
}

variable "instance_class" {
  type    = string
  default = "db.r7g.large"
}

variable "allocated_storage_gb" {
  type    = number
  default = 100
}

variable "max_allocated_storage_gb" {
  description = "Upper bound for storage autoscaling."
  type        = number
  default     = 1000
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "backup_retention_days" {
  description = "Point-in-time recovery window. 35 is the RDS maximum."
  type        = number
  default     = 14

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "Keep between 7 and 35 days of backups."
  }
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
