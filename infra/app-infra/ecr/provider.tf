provider "aws" {
  alias  = "west"
  region = "us-west-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Account     = var.account
      ManagedBy   = "Terraform"
      Stack       = "app-infra-ecr"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Account     = var.account
      ManagedBy   = "Terraform"
      Stack       = "app-infra-ecr"
    }
  }
}
