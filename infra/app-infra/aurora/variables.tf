variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "shopsphere"
}

variable "account" {
  description = "AWS account label. dev, qa, and uat use nonprod. preprod and prod use prod."
  type        = string

  validation {
    condition     = contains(["nonprod", "prod"], var.account)
    error_message = "Account must be nonprod or prod."
  }
}

variable "aws_region" {
  description = "AWS region for this Aurora cluster"
  type        = string
  default     = "us-east-1"
}

variable "environments" {
  description = "Environments served by this cluster. Non-prod passes dev, qa, and uat. Pre-prod and prod each pass one name."
  type        = set(string)

  validation {
    condition = alltrue([
      for env in var.environments : contains(["dev", "qa", "uat", "preprod", "prod"], env)
    ])
    error_message = "Environments must be dev, qa, uat, preprod, or prod."
  }

  validation {
    condition     = length(var.environments) > 0
    error_message = "Pass at least one environment."
  }
}

variable "network_state_bucket" {
  description = "S3 bucket that holds the network stack state"
  type        = string
}

variable "network_state_key" {
  description = "State key of the VPC that holds the RDS subnets"
  type        = string
}

variable "cluster_identifier" {
  description = "Aurora cluster identifier. Non-prod is one shared cluster. Pre-prod and prod each have their own."
  type        = string
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.10"
}

variable "database_name" {
  description = "Starter database created with the cluster. One database per environment is created later with SQL."
  type        = string
  default     = "postgres"
}

variable "master_username" {
  description = "Master username"
  type        = string
  default     = "shopsphere_admin"
}

variable "instances" {
  description = "Writer and reader instances"
  type = map(object({
    instance_class = string
    promotion_tier = number
  }))
}

variable "create_global_cluster" {
  description = "Create an Aurora Global Database and attach this cluster as the primary. False for non-prod. True for preprod and prod."
  type        = bool
  default     = false
}

variable "is_global_secondary" {
  description = "This apply is the us-west-1 reader for a pre-prod or prod Global Database. It does not create passwords, the proxy, or the connection secret."
  type        = bool
  default     = false
}

variable "primary_state_key" {
  description = "State key of the primary Aurora stack. Required when is_global_secondary is true."
  type        = string
  default     = null
}

variable "state_region" {
  description = "Region of the Terraform state bucket. The bucket stays in us-east-1 when the DR cluster is in us-west-1."
  type        = string
  default     = "us-east-1"
}

variable "backup_retention_period" {
  description = "Automated backup retention in days"
  type        = number
  default     = 7
}

variable "skip_final_snapshot" {
  description = "Skip the final snapshot on destroy. False for preprod and prod."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Block cluster deletion. True for preprod and prod."
  type        = bool
  default     = false
}
