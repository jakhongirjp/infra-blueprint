locals {
  name = "acme-staging"
  azs  = ["eu-central-1a", "eu-central-1b"]
  tags = {
    Environment = "staging"
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

# Same modules as production with cost-oriented inputs: two AZs, one NAT,
# single-AZ database, spot-heavy nodes.
module "network" {
  source             = "../../modules/network"
  name               = local.name
  cluster_name       = local.name
  cidr_block         = "10.20.0.0/16"
  availability_zones = local.azs
  single_nat_gateway = true
}

module "eks" {
  source              = "../../modules/eks"
  name                = local.name
  vpc_id              = module.network.vpc_id
  subnet_ids          = module.network.private_subnet_ids
  public_access_cidrs = var.operator_cidrs
  admin_role_arns     = var.admin_role_arns

  node_groups = {
    general = {
      instance_types = ["m7i.large", "m6i.large", "m5.large"]
      capacity_type  = "SPOT"
      min_size       = 2
      max_size       = 8
      desired_size   = 2
    }
  }
}

module "ledger_db" {
  source                     = "../../modules/postgres"
  name                       = "${local.name}-ledger"
  vpc_id                     = module.network.vpc_id
  subnet_ids                 = module.network.data_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]
  instance_class             = "db.t4g.medium"
  multi_az                   = false
  backup_retention_days      = 7
  deletion_protection        = false
}
