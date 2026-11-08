output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 cluster certificate authority data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "OIDC issuer URL of the EKS cluster"
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider_arn" {
  description = "ARN of the EKS IAM OIDC provider"
  value       = module.eks.oidc_provider_arn
}

output "private_subnet_ids" {
  description = "Private subnet IDs used by this cluster"
  value       = local.private_subnet_ids
}
