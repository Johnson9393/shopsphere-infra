resource "aws_security_group" "redis" {
  name        = "${var.environment}-${var.project_name}-redis"
  description = "Redis from this environment private subnets"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Redis from the environment private subnets"
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = local.private_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "mq" {
  name        = "${var.environment}-${var.project_name}-mq"
  description = "Amazon MQ from this environment private subnets"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "AMQPS from the environment private subnets"
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = local.private_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-${var.project_name}"
  subnet_ids = local.private_subnet_ids
}

resource "random_password" "redis" {
  length  = 32
  special = false
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.environment}-${var.project_name}"
  description          = "Redis for ${var.environment} ShopSphere"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  port                 = 6379
  parameter_group_name = "default.redis7"

  num_cache_clusters         = 2
  automatic_failover_enabled = true
  multi_az_enabled           = true

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis.result

  apply_immediately = true
}

resource "random_password" "mq" {
  length  = 32
  special = false
}

resource "aws_mq_broker" "rabbit" {
  broker_name                = "${var.environment}-${var.project_name}"
  engine_type                = "RabbitMQ"
  engine_version             = "3.13"
  host_instance_type         = var.mq_instance_type
  deployment_mode            = var.mq_deployment_mode
  subnet_ids                 = local.mq_subnet_ids
  security_groups            = [aws_security_group.mq.id]
  publicly_accessible        = false
  auto_minor_version_upgrade = true

  user {
    username = "shopsphere"
    password = random_password.mq.result
  }

  logs {
    general = true
  }
}

locals {
  mq_endpoint = aws_mq_broker.rabbit.instances[0].endpoints[0]
  mq_host     = replace(replace(local.mq_endpoint, "amqps://", ""), ":5671", "")
}

resource "aws_kms_key" "data" {
  description             = "Encrypts ${var.environment} ShopSphere data-service secrets"
  enable_key_rotation     = true
  deletion_window_in_days = 7
}

resource "aws_kms_alias" "data" {
  name          = "alias/${var.environment}-${var.project_name}-data"
  target_key_id = aws_kms_key.data.key_id
}

resource "aws_secretsmanager_secret" "redis" {
  name        = "${var.project_name}/${var.environment}/elasticache"
  description = "ElastiCache connection for ${var.environment}"
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = "6379"
    password = random_password.redis.result
  })
}

resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "aws_secretsmanager_secret" "application" {
  name        = "${var.project_name}/${var.environment}/application"
  description = "Application secrets for ${var.environment}"
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "application" {
  secret_id = aws_secretsmanager_secret.application.id
  secret_string = jsonencode({
    jwt = random_password.jwt.result
  })
}

resource "aws_secretsmanager_secret" "mq" {
  name        = "${var.project_name}/${var.environment}/amazonmq"
  description = "Amazon MQ connection for ${var.environment}"
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret" "cart" {
  name        = "${var.project_name}/${var.environment}/cart-service"
  description = "Cart service Redis login for ${var.environment}"
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "cart" {
  secret_id = aws_secretsmanager_secret.cart.id
  secret_string = jsonencode({
    host     = aws_elasticache_replication_group.redis.primary_endpoint_address
    port     = "6379"
    password = random_password.redis.result
  })
}

resource "aws_secretsmanager_secret" "notification" {
  name        = "${var.project_name}/${var.environment}/notification-service"
  description = "Notification service queue login for ${var.environment}"
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "notification" {
  secret_id = aws_secretsmanager_secret.notification.id
  secret_string = jsonencode({
    host     = local.mq_host
    port     = "5671"
    username = "shopsphere"
    password = random_password.mq.result
  })
}

resource "aws_secretsmanager_secret_version" "mq" {
  secret_id = aws_secretsmanager_secret.mq.id
  secret_string = jsonencode({
    host     = local.mq_host
    port     = "5671"
    username = "shopsphere"
    password = random_password.mq.result
  })
}
