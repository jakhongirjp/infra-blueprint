locals {
  name = "acme-production"
  azs  = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  tags = {
    Environment = "production"
    Owner       = "platform-team"
    CostCenter  = "engineering"
    ManagedBy   = "terraform"
    Repository  = "github.com/jakhongirjp/infra-blueprint"
  }
}

provider "aws" {
  region = "eu-central-1"
  default_tags {
    tags = local.tags
  }
}

module "network" {
  source             = "../../modules/network"
  name               = local.name
  cluster_name       = local.name
  cidr_block         = "10.10.0.0/16"
  availability_zones = local.azs
  single_nat_gateway = false
}

module "eks" {
  source              = "../../modules/eks"
  name                = local.name
  vpc_id              = module.network.vpc_id
  subnet_ids          = module.network.private_subnet_ids
  public_access_cidrs = var.operator_cidrs
  admin_role_arns     = var.admin_role_arns

  node_groups = {
    system = {
      instance_types = ["m7i.large"]
      min_size       = 3
      max_size       = 6
      desired_size   = 3
      labels         = { "workload-class" = "system" }
      taints         = [{ key = "CriticalAddonsOnly", value = "true", effect = "NO_SCHEDULE" }]
    }
    general = {
      instance_types = ["m7i.xlarge", "m6i.xlarge"]
      min_size       = 3
      max_size       = 30
      desired_size   = 3
    }
    batch-spot = {
      instance_types = ["c7i.xlarge", "c6i.xlarge", "c5.xlarge"]
      capacity_type  = "SPOT"
      min_size       = 0
      max_size       = 20
      desired_size   = 0
      labels         = { "workload-class" = "interruptible" }
      taints         = [{ key = "spot", value = "true", effect = "NO_SCHEDULE" }]
    }
  }
}

module "ledger_db" {
  source                     = "../../modules/postgres"
  name                       = "${local.name}-ledger"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.data_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.r7g.xlarge"
  backup_retention_days      = 35
}
