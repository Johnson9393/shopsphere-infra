output "vpc_id" {
  description = "ID of the shared VPC"
  value       = module.vpc.vpc_id
}

output "vpc_name" {
  description = "Name of the shared VPC"
  value       = module.vpc.vpc_name
}

output "vpc_cidr" {
  description = "CIDR block of the shared VPC"
  value       = var.vpc_cidr
}

output "public_subnet_ids" {
  description = "Shared public subnet IDs for NAT gateways and load balancers"
  value       = module.vpc.public_subnet_ids
}

output "rds_subnet_ids" {
  description = "Shared RDS subnet IDs for the Aurora cluster"
  value       = module.vpc.rds_subnet_ids
}

output "private_subnet_ids_by_environment" {
  description = "Private subnet IDs for each environment's EKS cluster"
  value       = local.private_subnet_ids_by_environment
}
