output "redis_primary_endpoint" {
  description = "ElastiCache primary endpoint"
  value       = aws_elasticache_replication_group.redis.primary_endpoint_address
}

output "redis_secret_arn" {
  description = "Secrets Manager ARN of the Redis connection"
  value       = aws_secretsmanager_secret.redis.arn
}

output "mq_host" {
  description = "Amazon MQ hostname"
  value       = local.mq_host
}

output "mq_secret_arn" {
  description = "Secrets Manager ARN of the Amazon MQ connection"
  value       = aws_secretsmanager_secret.mq.arn
}
