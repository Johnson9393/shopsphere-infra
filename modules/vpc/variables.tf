# vpc  cidr
variable "vpc_cidr" {
  type        = string
  description = "cidr for vpc "
}

# Allows instances and resources in the VPC to receive DNS hostnames, making it easier for services to communicate using names instead of IP addresses.
variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames in the VPC"
  default     = true
}

# Enables the AWS-provided DNS server inside the VPC, allowing resources to resolve domain names (such as AWS service endpoints, RDS endpoints, and internal hostnames) into IP addresses.
variable "enable_dns_support" {
  type    = bool
  default = true
}

variable "aws_region" {
  type        = string
  description = "AWS region to deploy the resources"
}

# vpc_name
variable "vpc_name" {
  type        = string
  description = "name of vpc"
}


variable "private_subnets" {
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "List of private subnets"

  validation {
    condition = var.need_single_ngw || (
      length(var.private_subnets) == length(var.public_subnets) &&
      length(distinct([for subnet in var.public_subnets : subnet.availability_zone])) == length(var.public_subnets) &&
      alltrue([
        for subnet in var.private_subnets :
        contains([for public_subnet in var.public_subnets : public_subnet.availability_zone], subnet.availability_zone)
      ])
    )

    error_message = "When using multiple NAT Gateways, public and private subnet counts must be equal, each public subnet must be in its own Availability Zone, and each private subnet must have a public subnet in that same zone."
  }
}

variable "public_subnets" {
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "List of public subnets"
}

variable "rds_subnets" {
  type = list(object({
    cidr              = string
    availability_zone = string
    prefix            = string
  }))
  description = "list of rds subnets"
}

variable "need_ngw" {
  type        = bool
  description = "If ngw is required"
}

variable "need_single_ngw" {
  type        = bool
  description = "Use one shared NAT gateway. Set false for one NAT gateway per Availability Zone."
}

variable "default_tags" {
  type        = map(string)
  description = "Default tags to apply to the resources"
  default = {
    module_name = "vpc"
  }
}
