variable "project_name" {
  description = "Project name used in resource names and tags"
  type        = string
  default     = "shopsphere"
}

variable "account" {
  description = "AWS account this VPC belongs to. non-prod is shared by dev, qa, and uat."
  type        = string
}

variable "aws_region" {
  description = "AWS region for this VPC"
  type        = string
  default     = "us-east-1"
}

variable "environments" {
  description = "Environments that share this VPC. Each one needs private subnets in at least two Availability Zones."
  type        = set(string)
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC. Public, private, and RDS subnets are cut from this range."
  type        = string
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "public_subnets" {
  description = "Shared public subnets, one per Availability Zone, for NAT gateways and load balancers."
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))

  validation {
    condition = (
      length(var.public_subnets) >= 2 &&
      length(distinct([for subnet in var.public_subnets : subnet.availability_zone])) == length(var.public_subnets)
    )
    error_message = "Provide at least two public subnets, each in its own Availability Zone."
  }
}

variable "private_subnets" {
  description = "Private subnets for EKS nodes. Prefix each subnet with the environment name, for example dev-private-1a."
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))

  validation {
    condition     = length(distinct([for subnet in var.private_subnets : subnet.prefix])) == length(var.private_subnets)
    error_message = "Private subnet prefixes must be unique."
  }

  validation {
    condition = alltrue([
      for subnet in var.private_subnets :
      contains(var.environments, split("-", subnet.prefix)[0])
    ])
    error_message = "Each private subnet prefix must start with an environment name from var.environments, for example dev-private-1a."
  }

  validation {
    condition = alltrue([
      for env in var.environments :
      length(distinct([
        for subnet in var.private_subnets : subnet.availability_zone
        if startswith(subnet.prefix, "${env}-")
      ])) >= 2
    ])
    error_message = "Each environment needs private subnets in at least two Availability Zones."
  }

  validation {
    condition = var.need_single_ngw || alltrue([
      for subnet in var.private_subnets :
      contains([for public_subnet in var.public_subnets : public_subnet.availability_zone], subnet.availability_zone)
    ])
    error_message = "With one NAT gateway per Availability Zone, every private subnet must be in a zone that has a public subnet."
  }
}

variable "rds_subnets" {
  description = "Shared RDS subnets, one per Availability Zone, for the Aurora cluster."
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))

  validation {
    condition = (
      length(var.rds_subnets) >= 2 &&
      length(distinct([for subnet in var.rds_subnets : subnet.availability_zone])) == length(var.rds_subnets)
    )
    error_message = "Provide at least two RDS subnets, each in its own Availability Zone."
  }
}

variable "need_ngw" {
  description = "Create NAT gateways for private subnet egress"
  type        = bool
}

variable "need_single_ngw" {
  description = "Use one shared NAT gateway. False creates one NAT gateway per public subnet Availability Zone."
  type        = bool
}
