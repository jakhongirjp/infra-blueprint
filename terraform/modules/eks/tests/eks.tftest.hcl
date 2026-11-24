mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = { partition = "aws" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  name       = "acme-test"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-a", "subnet-b", "subnet-c"]
  node_groups = {
    general = { instance_types = ["m7i.large"], min_size = 2, max_size = 6, desired_size = 3 }
    spot    = { instance_types = ["m7i.large", "m6i.large"], capacity_type = "SPOT", min_size = 0, max_size = 10, desired_size = 0 }
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = aws_eks_cluster.this.vpc_config[0].endpoint_public_access == false
    error_message = "The API endpoint must be private unless CIDRs are allow-listed."
  }

  assert {
    condition     = contains(aws_eks_cluster.this.enabled_cluster_log_types, "audit")
    error_message = "Audit logging must be enabled."
  }

  assert {
    condition     = aws_eks_cluster.this.access_config[0].bootstrap_cluster_creator_admin_permissions == false
    error_message = "Admin access must be granted explicitly, not to whoever ran terraform."
  }

  assert {
    condition     = alltrue([for lt in aws_launch_template.node : lt.metadata_options[0].http_tokens == "required"])
    error_message = "Nodes must enforce IMDSv2."
  }

  assert {
    condition     = alltrue([for lt in aws_launch_template.node : lt.block_device_mappings[0].ebs[0].encrypted == "true"])
    error_message = "Node volumes must be encrypted."
  }

  assert {
    condition     = aws_kms_key.secrets.enable_key_rotation
    error_message = "KMS key rotation must be enabled."
  }
}

run "node_groups_from_map" {
  command = plan

  assert {
    condition     = aws_eks_node_group.this["spot"].capacity_type == "SPOT" && length(aws_eks_node_group.this) == 2
    error_message = "Node groups should be created from the input map."
  }
}

run "rejects_world_open_api" {
  command = plan
  variables {
    public_access_cidrs = ["0.0.0.0/0"]
  }
  expect_failures = [var.public_access_cidrs]
}

run "rejects_bad_scaling" {
  command = plan
  variables {
    node_groups = {
      broken = { instance_types = ["m7i.large"], min_size = 5, max_size = 2, desired_size = 3 }
    }
  }
  expect_failures = [var.node_groups]
}
