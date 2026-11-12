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

variable "mq_instance_type" {
  description = "Amazon MQ broker size. RabbitMQ multi-AZ needs mq.m5.large or larger."
  type        = string
  default     = "mq.t3.micro"
}

variable "mq_deployment_mode" {
  description = "SINGLE_INSTANCE for non-prod. CLUSTER_MULTI_AZ for a production broker."
  type        = string
  default     = "SINGLE_INSTANCE"

  validation {
    condition     = contains(["SINGLE_INSTANCE", "CLUSTER_MULTI_AZ"], var.mq_deployment_mode)
    error_message = "MQ deployment mode must be SINGLE_INSTANCE or CLUSTER_MULTI_AZ."
  }
}
