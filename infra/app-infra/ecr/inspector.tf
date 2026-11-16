# Amazon Inspector enhanced scanning. One setting per registry.
# The dev stack enables it in the non-prod account. The prod stack enables it in the prod account.
# Each account gets it in us-east-1 and us-west-1, because images are replicated to both regions.

locals {
  enable_inspector = var.environment == "dev" || (var.environment == "prod" && var.replication_source_account_id != "")
}

resource "aws_inspector2_enabler" "ecr" {
  count = local.enable_inspector ? 1 : 0

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

resource "aws_inspector2_enabler" "ecr_west" {
  count    = local.enable_inspector ? 1 : 0
  provider = aws.west

  account_ids    = [data.aws_caller_identity.current.account_id]
  resource_types = ["ECR"]
}

resource "aws_ecr_registry_scanning_configuration" "inspector" {
  count = local.enable_inspector ? 1 : 0

  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"

    repository_filter {
      filter      = "${var.project_name}-*"
      filter_type = "WILDCARD"
    }
  }

  depends_on = [aws_inspector2_enabler.ecr]
}

resource "aws_ecr_registry_scanning_configuration" "inspector_west" {
  count    = local.enable_inspector ? 1 : 0
  provider = aws.west

  scan_type = "ENHANCED"

  rule {
    scan_frequency = "CONTINUOUS_SCAN"

    repository_filter {
      filter      = "${var.project_name}-*"
      filter_type = "WILDCARD"
    }
  }

  depends_on = [aws_inspector2_enabler.ecr_west]
}
