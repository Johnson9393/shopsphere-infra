# It will give current account ID
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Repositories created after 15 July 2026 send owner and repository IDs in sub.
  # A name-only pattern does not match that token.
  terraform_oidc_subject = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_infra_repository}@${var.github_infra_repository_id}:*"
  ecr_oidc_subject       = "repo:${var.github_owner}@${var.github_owner_id}/${var.github_app_repository}@${var.github_app_repository_id}:*"

  ecr_repository_arn_patterns = {
    for env in var.environments :
    env => "arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${env}-${var.project_name}-*"
  }
}
