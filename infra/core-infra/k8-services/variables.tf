variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "shopsphere"
}

variable "environment" {
  description = "Environment whose cluster receives these add-ons."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "uat", "preprod", "prod"], var.environment)
    error_message = "Environment must be dev, qa, uat, preprod, or prod."
  }
}

variable "account" {
  description = "AWS account label. dev, qa, and uat use nonprod."
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "state_region" {
  description = "Region of the Terraform state bucket. Stays us-east-1 for a us-west-1 cluster."
  type        = string
  default     = "us-east-1"
}

variable "state_bucket" {
  description = "S3 bucket that holds the EKS stack state"
  type        = string
}

variable "eks_state_key" {
  description = "State key of this environment's EKS cluster"
  type        = string
}

variable "cluster_autoscaler_chart_version" {
  description = "Cluster Autoscaler Helm chart version"
  type        = string
  default     = "9.46.0"
}

variable "git_repo_url" {
  description = "Git repository Argo CD syncs"
  type        = string
  default     = "https://github.com/Johnson9393/shopsphere.git"
}

variable "domain_name" {
  description = "Public zone in the management account. Records are <name>.<environment>.<domain>."
  type        = string
  default     = "infralabx.space"
}

variable "dns_assume_role_arn" {
  description = "Role in the management account that can change the public hosted zone."
  type        = string
}

variable "enable_shield_advanced" {
  description = "Attach Shield Advanced. Requires an active Shield Advanced subscription. Shield Standard is already on."
  type        = bool
  default     = false
}
