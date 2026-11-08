output "repository_urls" {
  description = "ECR repository URL per service"
  value       = { for name, repo in aws_ecr_repository.service : name => repo.repository_url }
}
