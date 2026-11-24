mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  name                       = "acme-test"
  vpc_id                     = "vpc-12345678"
  subnet_ids                 = ["subnet-a", "subnet-b"]
  allowed_security_group_ids = ["sg-eks"]
}

run "production_guardrails" {
  command = plan

  assert {
    condition     = aws_db_instance.this.storage_encrypted && !aws_db_instance.this.publicly_accessible
    error_message = "Database must be encrypted and private."
  }

  assert {
    condition     = aws_db_instance.this.multi_az && aws_db_instance.this.deletion_protection
    error_message = "Production defaults need Multi-AZ and deletion protection."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password
    error_message = "Master password must be managed by Secrets Manager, never in state."
  }

  assert {
    condition     = one([for p in aws_db_parameter_group.this.parameter : p.value if p.name == "rds.force_ssl"]) == "1"
    error_message = "TLS must be enforced."
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.app) == 1 && aws_vpc_security_group_ingress_rule.app["sg-eks"].from_port == 5432
    error_message = "Only the listed security groups may reach 5432."
  }
}

run "short_backup_window_is_rejected" {
  command = plan
  variables {
    backup_retention_days = 1
  }
  expect_failures = [var.backup_retention_days]
}
