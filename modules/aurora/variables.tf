variable "env" {
  description = "Environment key (dev, qa, uat, preprod, prod) or a shared key such as nonprod. Used in names and tags only."
  type        = string
}

variable "cluster_identifier" {
  description = "Aurora cluster identifier. Defaults to <env>-shopsphere."
  type        = string
  default     = null
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version."
  type        = string
  default     = "15.10"
}

variable "database_name" {
  description = "Starter database AWS must create on a primary cluster. App databases (one per env) are created later with SQL, not here."
  type        = string
  default     = "postgres"
}

variable "master_username" {
  description = "Master username for a primary cluster. Ignored on a Global Database secondary."
  type        = string
  default     = "shopsphere_admin"
}

variable "vpc_id" {
  description = "VPC that holds the RDS subnets and this security group."
  type        = string
}

variable "rds_subnet_ids" {
  description = "Private RDS subnet IDs in at least two Availability Zones."
  type        = list(string)

  validation {
    condition     = length(var.rds_subnet_ids) >= 2
    error_message = "Aurora needs RDS subnets in at least two Availability Zones."
  }
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach Postgres (EKS cluster SGs). Non-prod shared Aurora passes all three cluster SGs."
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "Optional CIDRs allowed to reach Postgres (VPN / Client VPN). Empty means none."
  type        = list(string)
  default     = []
}

variable "instances" {
  description = "Aurora instances keyed by a stable name. Two entries = writer + reader HA."
  type = map(object({
    instance_class = string
    promotion_tier = number
  }))

  default = {
    writer = {
      instance_class = "db.t3.medium"
      promotion_tier = 1
    }
    reader = {
      instance_class = "db.t3.medium"
      promotion_tier = 2
    }
  }
}

variable "create_global_cluster" {
  description = "Create an Aurora Global Database and attach this cluster as the primary (preprod/prod in us-east-1)."
  type        = bool
  default     = false
}

variable "is_global_secondary" {
  description = "This cluster is a Global Database secondary (DR region). No master password. Requires global_cluster_identifier."
  type        = bool
  default     = false
}

variable "global_cluster_identifier" {
  description = "Existing global cluster id. Required when is_global_secondary is true. Ignored when create_global_cluster is true."
  type        = string
  default     = null
}

variable "kms_key_arn" {
  description = "Optional CMK for storage encryption. Null uses the AWS-managed RDS key. Secondary regions should pass a key in that region."
  type        = string
  default     = null
}

variable "backup_retention_period" {
  description = "Automated backup retention in days."
  type        = number
  default     = 7
}

variable "preferred_backup_window" {
  description = "Daily backup window (UTC)."
  type        = string
  default     = "07:00-09:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly maintenance window (UTC)."
  type        = string
  default     = "sun:09:00-sun:11:00"
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy. False for preprod/prod."
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Block accidental cluster delete. True for preprod/prod."
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply modifications immediately instead of the maintenance window."
  type        = bool
  default     = false
}

variable "enabled_cloudwatch_logs_exports" {
  description = "Log types to export to CloudWatch."
  type        = list(string)
  default     = ["postgresql"]
}

variable "default_tags" {
  description = "Default tags applied to Aurora resources."
  type        = map(string)
  default = {
    module_name = "aurora"
  }
}

variable "port" {
  description = "Postgres port."
  type        = number
  default     = 5432
}
