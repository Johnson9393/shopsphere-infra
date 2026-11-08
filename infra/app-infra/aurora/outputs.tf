output "cluster_identifier" {
  description = "Aurora cluster identifier"
  value       = module.aurora.cluster_id
}

output "writer_endpoint" {
  description = "Endpoint for writes"
  value       = module.aurora.writer_endpoint
}

output "reader_endpoint" {
  description = "Endpoint for reads"
  value       = module.aurora.reader_endpoint
}

output "port" {
  description = "Postgres port"
  value       = module.aurora.port
}

output "database_name" {
  description = "Starter database created with the cluster"
  value       = module.aurora.database_name
}

output "security_group_id" {
  description = "Aurora security group id"
  value       = module.aurora.security_group_id
}

output "global_cluster_id" {
  description = "Aurora Global Database id. Null when this cluster is regional only."
  value       = module.aurora.global_cluster_id
}

output "master_user_secret_arn" {
  description = "Secrets Manager ARN of the Aurora-managed master password. The password is not in this output."
  value       = module.aurora.master_user_secret_arn
}

output "connection_secret_arn" {
  description = "Secrets Manager ARN of the Aurora endpoints"
  value       = aws_secretsmanager_secret.connection.arn
}
