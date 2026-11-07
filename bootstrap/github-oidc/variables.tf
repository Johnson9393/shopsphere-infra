variable "project_name" {
  description = "Project name used in IAM and ECR naming"
  type        = string
  default     = "shopsphere"
}

variable "aws_region" {
  description = "AWS region for this bootstrap apply"
  type        = string
  default     = "us-east-1"
}

variable "environments" {
  description = "Environments in this AWS account. non-prod: dev, qa, uat. prod account: preprod, prod."
  type        = set(string)
}

variable "github_owner" {
  description = "GitHub user or organization that owns the ShopSphere repos"
  type        = string
}

variable "github_infra_repository" {
  description = "GitHub repository that runs Terraform (shopsphere-infra)"
  type        = string
  default     = "shopsphere-infra"
}

variable "github_app_repository" {
  description = "GitHub repository that builds and pushes images (shopsphere)"
  type        = string
  default     = "shopsphere"
}

variable "github_branch" {
  description = "Branch allowed to assume these roles"
  type        = string
  default     = "main"
}

variable "terraform_role_name_prefix" {
  description = "Prefix for per-environment Terraform IAM roles"
  type        = string
  default     = "shopsphere-github-terraform"
}

variable "ecr_role_name_prefix" {
  description = "Prefix for per-environment ECR push IAM roles"
  type        = string
  default     = "shopsphere-github-ecr"
}
