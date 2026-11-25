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

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.environment}-${var.project_name}"
  subnet_ids = local.private_subnet_ids
}

locals {
  redis_user_id              = "${var.environment}-${var.project_name}-cart"
  redis_replication_group_id = "${var.environment}-${var.project_name}"
}

# The account already has a default Redis user. CreateUser would fail, so each
# environment turns that user off. A connection without the IAM user is rejected.
resource "terraform_data" "lock_default_redis_user" {
  triggers_replace = {
    region = var.aws_region
    access = "off -@all"
  }

  provisioner "local-exec" {
    command = "aws elasticache modify-user --region ${var.aws_region} --user-id default --access-string 'off -@all' --authentication-mode Type=no-password-required"
  }
}

resource "aws_elasticache_user" "cart" {
  user_id       = local.redis_user_id
  user_name     = local.redis_user_id
  engine        = "REDIS"
  access_string = "on ~* +@all"

  authentication_mode {
    type = "iam"
  }
}

resource "aws_elasticache_user_group" "cart" {
  engine        = "REDIS"
  user_group_id = local.redis_replication_group_id
  user_ids      = ["default", aws_elasticache_user.cart.user_id]

  depends_on = [terraform_data.lock_default_redis_user]
}

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = local.redis_replication_group_id
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
  user_group_ids     = [aws_elasticache_user_group.cart.user_group_id]

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true

  apply_immediately = true
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
  description = "ElastiCache endpoint for ${var.environment}. Authentication is IAM."
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "redis" {
  secret_id = aws_secretsmanager_secret.redis.id
  secret_string = jsonencode({
    host                 = aws_elasticache_replication_group.redis.primary_endpoint_address
    port                 = "6379"
    username             = aws_elasticache_user.cart.user_name
    replication_group_id = aws_elasticache_replication_group.redis.id
    auth                 = "iam"
    tls                  = "true"
  })
}

resource "aws_secretsmanager_secret" "cart" {
  name        = "${var.project_name}/${var.environment}/cart-service"
  description = "Cart service Redis endpoint for ${var.environment}. Authentication is IAM."
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "cart" {
  secret_id = aws_secretsmanager_secret.cart.id
  secret_string = jsonencode({
    host                 = aws_elasticache_replication_group.redis.primary_endpoint_address
    port                 = "6379"
    username             = aws_elasticache_user.cart.user_name
    replication_group_id = aws_elasticache_replication_group.redis.id
    auth                 = "iam"
    tls                  = "true"
  })
}
