terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.74" }
  }

  # Native S3 locking (use_lockfile) replaces the DynamoDB lock table.
  backend "s3" {
    key          = "staging/terraform.tfstate"
    region       = "eu-central-1"
    encrypt      = true
    use_lockfile = true
    # bucket is passed with -backend-config=bucket=<name> so forks need no edits.
  }
}
