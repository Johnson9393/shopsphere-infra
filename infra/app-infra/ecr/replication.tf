data "aws_caller_identity" "current" {}

locals {
  # One registry per account. Dev owns the non-prod repositories.
  # QA and UAT pull the same repositories. Prod only allows replication in.
  manage_repositories = var.environment == "dev"
}

resource "aws_ecr_replication_configuration" "prod" {
  count = local.manage_repositories && var.replication_destination_registry_id != "" ? 1 : 0

  replication_configuration {
    rule {
      destination {
        region      = "us-west-1"
        registry_id = data.aws_caller_identity.current.account_id
      }

      destination {
        region      = var.aws_region
        registry_id = var.replication_destination_registry_id
      }

      destination {
        region      = "us-west-1"
        registry_id = var.replication_destination_registry_id
      }

      repository_filter {
        filter      = "${var.project_name}-"
        filter_type = "PREFIX_MATCH"
      }
    }
  }
}

locals {
  allow_replication = var.environment == "prod" && var.replication_source_account_id != ""
}

resource "aws_ecr_registry_policy" "replication" {
  count = local.allow_replication ? 1 : 0

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowNonProdReplication"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.replication_source_account_id}:root" }
        Action    = ["ecr:CreateRepository", "ecr:ReplicateImage"]
        Resource  = "arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
      }
    ]
  })
}

resource "aws_ecr_registry_policy" "replication_west" {
  count    = local.allow_replication ? 1 : 0
  provider = aws.west

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowNonProdReplication"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.replication_source_account_id}:root" }
        Action    = ["ecr:CreateRepository", "ecr:ReplicateImage"]
        Resource  = "arn:aws:ecr:us-west-1:${data.aws_caller_identity.current.account_id}:repository/${var.project_name}-*"
      }
    ]
  })
}
