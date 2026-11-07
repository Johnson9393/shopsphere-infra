output "github_oidc_provider_arn" {
  description = "GitHub OIDC provider ARN in this account"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_terraform_role_arns" {
  description = "Terraform IAM role ARN per environment"
  value       = { for env, role in aws_iam_role.github_terraform : env => role.arn }
}

output "github_ecr_role_arns" {
  description = "ECR push IAM role ARN per environment"
  value       = { for env, role in aws_iam_role.github_ecr : env => role.arn }
}
