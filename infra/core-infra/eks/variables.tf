variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "shopsphere"
}

variable "environment" {
  description = "Environment for this cluster. Non-prod values are dev, qa, and uat."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "uat", "preprod", "prod"], var.environment)
    error_message = "Environment must be dev, qa, uat, preprod, or prod."
  }
}

variable "account" {
  description = "AWS account label for this cluster. dev, qa, and uat use nonprod."
  type        = string
}

variable "aws_region" {
  description = "AWS region for this cluster"
  type        = string
  default     = "us-east-1"
}

variable "network_state_bucket" {
  description = "S3 bucket that holds the network stack state"
  type        = string
}

variable "network_state_key" {
  description = "State key of the VPC this cluster joins"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name. One cluster per environment."
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the control plane and node groups"
  type        = string
}

variable "endpoint_private_access" {
  description = "Enable private access to the Kubernetes API"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public access to the Kubernetes API"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public Kubernetes API"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_admin_role_arns" {
  description = "IAM role ARNs granted cluster admin. The role that creates the cluster is already an admin."
  type        = list(string)
  default     = []
}

variable "eks_nodes" {
  description = "Managed node groups for this cluster"

  type = map(object({
    instance_type      = string
    desired_size       = number
    min_size           = number
    max_size           = number
    kubernetes_version = string
  }))
}

variable "ami_type" {
  description = "AMI type for the managed node groups"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}
