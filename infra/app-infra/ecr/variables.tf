variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "shopsphere"
}

variable "environment" {
  description = "Environment for these repositories. Non-prod values are dev, qa, and uat."
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
  description = "AWS region for these repositories"
  type        = string
  default     = "us-east-1"
}

variable "replication_destination_registry_id" {
  description = "Prod account that receives a copy of every shopsphere image. Set on the dev stack only. Dev, QA, and UAT share these repositories."
  type        = string
  default     = ""
}

variable "replication_source_account_id" {
  description = "Non-prod account allowed to replicate images into this registry. Set on the prod stack only."
  type        = string
  default     = ""
}

variable "services" {
  description = "Container repositories. One per ShopSphere service."
  type        = set(string)
  default = [
    "frontend",
    "api-gateway",
    "product-service",
    "user-service",
    "cart-service",
    "order-service",
    "payment-service",
    "notification-service",
    "seed",
  ]
}
