variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "shopsphere"
}

variable "environment" {
  description = "Environment for this Redis and Amazon MQ pair."
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
  description = "Region of the Terraform state bucket. Stays us-east-1 for a us-west-1 data stack."
  type        = string
  default     = "us-east-1"
}

variable "network_state_bucket" {
  description = "S3 bucket that holds the network stack state"
  type        = string
}

variable "network_state_key" {
  description = "State key of the VPC this environment uses"
  type        = string
}

variable "redis_node_type" {
  description = "ElastiCache node size"
  type        = string
  default     = "cache.t4g.micro"
}

variable "extra_client_cidrs" {
  description = "Additional CIDRs that may reach MSK. Pre-prod and prod include the other region's VPC so replication can cross the peering connection."
  type        = list(string)
  default     = []
}

variable "msk_instance_type" {
  description = "MSK broker size. Two brokers, one in each private subnet."
  type        = string
  default     = "kafka.t3.small"
}

variable "msk_volume_size" {
  description = "EBS volume size in GiB for each MSK broker."
  type        = number
  default     = 20
}

variable "primary_state_bucket" {
  description = "State bucket of the primary-region data stack. Set on the DR data stack."
  type        = string
  default     = ""
}

variable "primary_state_key" {
  description = "State key of the primary-region data stack. Set on the DR data stack so MSK replication can find the source cluster."
  type        = string
  default     = ""
}

