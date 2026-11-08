provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      Account   = var.account
      ManagedBy = "Terraform"
      Stack     = "core-infra-network"
    }
  }
}
