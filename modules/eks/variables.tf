variable "env" {
  description = "Environment key for this ShopSphere deployment."
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the EKS cluster will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EKS cluster and worker nodes"
  type        = list(string)
}

variable "endpoint_private_access" {
  description = "Enable private access to the EKS Kubernetes API endpoint"
  type        = bool
  default     = true
}

# Enable public access to the EKS Kubernetes API endpoint
variable "endpoint_public_access" {
  description = "Enable public access to the EKS Kubernetes API endpoint"
  type        = bool
  default     = true
}

# Which cidr range is allowed to access public eks api endpoint, if not provided, all ip addresses will be allowed
variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS API endpoint"
  type        = list(string)
  default     = []
}

# Choose service ipv4 cidr for kubernetes services, if not provided, default will be used
variable "cluster_service_ipv4_cidr" {
  description = "IPv4 CIDR block for Kubernetes services"
  type        = string
  default     = null
}

variable "cluster_log_types" {
  description = "EKS control plane log types to enable"
  type        = list(string)

  default = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]
}

variable "enable_cluster_logs" {
  description = "Enable EKS control plane logging"
  type        = bool
  default     = true
}

variable "cluster_encryption_enabled" {
  description = "Enable envelope encryption for Kubernetes secrets"
  type        = bool
  default     = true
}

# K8 secrets stored in etcd are encrypted at rest using envelope encryption. This requires a KMS key ARN to be provided for the encryption.
variable "cluster_encryption_key_arn" {
  description = "KMS key ARN used for EKS secrets encryption"
  type        = string
  default     = null
}

variable "default_tags" {
  description = "Default tags applied to EKS resources"
  type        = map(string)
  default = {
    module_name = "eks"
  }
}

variable "cluster_admin_role_arns" {
  type    = list(string)
  default = []
}

variable "eks_nodes" {
  description = "EKS managed node groups"

  type = map(object({
    instance_type = string
    desired_size  = number
    min_size      = number
    max_size      = number
    kubernetes_version = string
  }))

  default = {
    application = {
      instance_type = "t3.medium"
      desired_size  = 3
      min_size      = 2
      max_size      = 5
      kubernetes_version = "1.33"
    }
  }
}

variable "ami_type" {
  description = "The AMI type for the EKS managed node group"
  type        = string
  default     = "AL2023_x86_64_STANDARD"
}

