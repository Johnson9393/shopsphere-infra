# It will give current account ID
data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Trust the infra repo for Terraform applies.
  terraform_oidc_subjects = {
    for env in var.environments :
    env => [
      "repo:${var.github_owner}/${var.github_infra_repository}:ref:refs/heads/${var.github_branch}",
      "repo:${var.github_owner}/${var.github_infra_repository}:environment:${env}",
    ]
  }

  # Trust the app repo for image pushes.
  ecr_oidc_subjects = {
    for env in var.environments :
    env => [
      "repo:${var.github_owner}/${var.github_app_repository}:ref:refs/heads/${var.github_branch}",
      "repo:${var.github_owner}/${var.github_app_repository}:environment:${env}",
    ]
  }

  ecr_repository_arn_patterns = {
    for env in var.environments :
    env => "arn:aws:ecr:${var.aws_region}:${local.account_id}:repository/${env}-${var.project_name}-*"
  }
}
