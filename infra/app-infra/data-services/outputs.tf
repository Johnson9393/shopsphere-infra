output "redis_primary_endpoint" {
  description = "ElastiCache primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_secret_arn" {
  description = "Secrets Manager ARN of the Redis connection"
  value       = aws_secretsmanager_secret.redis.arn
}

output "private_subnet_ids" {
  description = "Private subnets used by this environment's data services"
  value       = local.private_subnet_ids
}

output "msk_security_group_id" {
  description = "Security group attached to the MSK brokers"
  value       = aws_security_group.msk.id
}

output "msk_cluster_arn" {
  description = "MSK cluster ARN"
  value       = aws_msk_cluster.this.arn
}

output "kafka_secret_arn" {
  description = "Secrets Manager ARN of the MSK connection"
  value       = aws_secretsmanager_secret.kafka.arn
}
