mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "eu-central-1" }
  }
  mock_data "aws_iam_policy_document" {
    defaults = { json = "{}" }
  }
}

variables {
  name               = "acme-test"
  cluster_name       = "acme-test"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

run "three_tiers_per_az" {
  command = plan

  assert {
    condition     = length(aws_subnet.public) == 3 && length(aws_subnet.private) == 3 && length(aws_subnet.data) == 3
    error_message = "Expected one subnet per tier per AZ."
  }

  assert {
    condition     = output.subnet_cidrs.private == ["10.0.64.0/19", "10.0.96.0/19", "10.0.128.0/19"]
    error_message = "Private subnets must be /19s starting at 10.0.64.0."
  }

  assert {
    condition     = output.subnet_cidrs.data == ["10.0.224.0/22", "10.0.228.0/22", "10.0.232.0/22"]
    error_message = "Data subnets must be /22s at the top of the range."
  }
}

run "no_subnet_overlap_with_four_azs" {
  command = plan

  variables {
    availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c", "eu-central-1d"]
  }

  # The VPC precondition fails the plan if any computed subnets overlap.
  assert {
    condition     = length(output.subnet_cidrs.public) == 4
    error_message = "Expected four public subnets."
  }
}

run "small_vpc_still_fits" {
  command = plan

  variables {
    cidr_block = "172.20.0.0/18"
  }

  assert {
    condition     = output.subnet_cidrs.data[0] == "172.20.56.0/24"
    error_message = "Layout should scale down to a /18 without overlap."
  }
}

run "nat_per_az_by_default" {
  command = plan

  assert {
    condition     = length(aws_nat_gateway.this) == 3
    error_message = "Production layout needs a NAT gateway in every AZ."
  }

  assert {
    condition     = aws_subnet.public[0].map_public_ip_on_launch == false
    error_message = "Public subnets must not auto-assign public IPs."
  }
}

run "single_nat_for_non_production" {
  command = plan

  variables {
    single_nat_gateway = true
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1
    error_message = "single_nat_gateway should create exactly one NAT gateway."
  }
}

run "rejects_one_az" {
  command = plan

  variables {
    availability_zones = ["eu-central-1a"]
  }

  expect_failures = [var.availability_zones]
}
