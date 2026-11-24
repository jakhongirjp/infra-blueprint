# Managed PostgreSQL with the guardrails a production ledger needs:
# Multi-AZ, encryption with a dedicated key, forced TLS, PITR, no public
# access, and a master password that never appears in Terraform state
# (managed by RDS in Secrets Manager).

resource "aws_kms_key" "this" {
  description             = "Storage encryption for ${var.name} PostgreSQL"
  deletion_window_in_days = 30
  enable_key_rotation     = true
  tags                    = var.tags
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids
  tags       = var.tags
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name}-pg-"
  description = "PostgreSQL access from application workloads only"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-postgres" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  for_each                     = toset(var.allowed_security_group_ids)
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = each.value
  ip_protocol                  = "tcp"
  from_port                    = 5432
  to_port                      = 5432
  description                  = "PostgreSQL from ${each.value}"
}

resource "aws_db_parameter_group" "this" {
  name_prefix = "${var.name}-pg17-"
  family      = "postgres17"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  # Log statements slower than 500 ms and every lock wait; both feed dashboards.
  parameter {
    name  = "log_min_duration_statement"
    value = "500"
  }

  parameter {
    name  = "log_lock_waits"
    value = "1"
  }

  parameter {
    name         = "shared_preload_libraries"
    value        = "pg_stat_statements"
    apply_method = "pending-reboot"
  }

  # Kill sessions that sit idle inside a transaction holding locks.
  parameter {
    name  = "idle_in_transaction_session_timeout"
    value = "60000"
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_iam_policy_document" "monitoring_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  name               = "${var.name}-rds-monitoring"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  role       = aws_iam_role.monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = "postgres"
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage_gb
  max_allocated_storage = var.max_allocated_storage_gb
  storage_type          = "gp3"
  storage_encrypted     = true
  kms_key_id            = aws_kms_key.this.arn

  db_name                             = "app"
  username                            = "app_admin"
  manage_master_user_password         = true
  iam_database_authentication_enabled = true

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.this.name
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_days
  backup_window             = "02:00-03:00"
  maintenance_window        = "sun:03:30-sun:04:30"
  copy_tags_to_snapshot     = true
  delete_automated_backups  = false
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = false
  final_snapshot_identifier = "${var.name}-final"

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  performance_insights_enabled          = true
  performance_insights_kms_key_id       = aws_kms_key.this.arn
  performance_insights_retention_period = 7
  monitoring_interval                   = 30
  monitoring_role_arn                   = aws_iam_role.monitoring.arn
  enabled_cloudwatch_logs_exports       = ["postgresql", "upgrade"]

  tags = var.tags
}

# --- Alarms ----------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "cpu" {
  alarm_name          = "${var.name}-pg-cpu-high"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.this.identifier }
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 3
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"
  alarm_description   = "Sustained CPU above 80% for 15 minutes."
  tags                = var.tags
}

resource "aws_cloudwatch_metric_alarm" "free_storage" {
  alarm_name          = "${var.name}-pg-storage-low"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  dimensions          = { DBInstanceIdentifier = aws_db_instance.this.identifier }
  statistic           = "Minimum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 10 * 1024 * 1024 * 1024
  comparison_operator = "LessThanThreshold"
  alarm_description   = "Less than 10 GiB free; autoscaling may be capped."
  tags                = var.tags
}
