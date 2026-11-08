provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Account     = var.account
      Environment = local.cluster_env
      ManagedBy   = "Terraform"
      Stack       = "app-infra-aurora"
    }
  }
}
