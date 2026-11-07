output "cluster_id" {
  description = "Regional Aurora cluster identifier."
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Regional Aurora cluster ARN."
  value       = aws_rds_cluster.this.arn
}

output "cluster_resource_id" {
  description = "Cluster resource id (used by RDS Proxy and IAM auth)."
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "writer_endpoint" {
  description = "Cluster writer endpoint. Apps use this for writes."
  value       = aws_rds_cluster.this.endpoint
}

output "reader_endpoint" {
  description = "Cluster reader endpoint. Apps use this for reads."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "port" {
  description = "Postgres port."
  value       = aws_rds_cluster.this.port
}

output "master_username" {
  description = "Master username. Null on a Global Database secondary."
  value       = local.is_primary ? var.master_username : null
}

output "master_password" {
  description = "Generated master password. Store in Secrets Manager in app-infra. Null on a secondary."
  value       = local.is_primary ? random_password.master[0].result : null
  sensitive   = true
}

output "database_name" {
  description = "Starter database name on the primary."
  value       = var.database_name
}

output "security_group_id" {
  description = "Aurora security group id."
  value       = aws_security_group.this.id
}

output "db_subnet_group_name" {
  description = "DB subnet group name."
  value       = aws_db_subnet_group.this.name
}

output "global_cluster_id" {
  description = "Global cluster id when this module created it. Null otherwise."
  value       = var.create_global_cluster ? aws_rds_global_cluster.this[0].id : null
}

output "instance_ids" {
  description = "Aurora instance identifiers."
  value       = [for instance in aws_rds_cluster_instance.this : instance.id]
}
