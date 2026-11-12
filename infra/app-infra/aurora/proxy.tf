data "aws_subnet" "application" {
  for_each = toset(flatten([
    for env in var.environments :
    data.terraform_remote_state.network.outputs.private_subnet_ids_by_environment[env]
  ]))
  id = each.value
}

locals {
  application_cidrs = [for subnet in data.aws_subnet.application : subnet.cidr_block]
  proxy_auth_secrets = local.is_primary ? merge(
    { (module.aurora.master_user_secret_arn) = "Aurora master user" },
    { for env, secret in aws_secretsmanager_secret.application : secret.arn => "${env} application user" },
  ) : {}
}

resource "aws_security_group" "proxy" {
  count = local.is_primary ? 1 : 0

  name        = "${var.cluster_identifier}-proxy"
  description = "RDS Proxy from application private subnets"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "application private subnets to RDS proxy"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.application_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "aurora_from_proxy" {
  count = local.is_primary ? 1 : 0

  type                     = "ingress"
  description              = "Proxy to Aurora"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.aurora.security_group_id
  source_security_group_id = aws_security_group.proxy[0].id
}

resource "aws_iam_role" "proxy" {
  count = local.is_primary ? 1 : 0

  name = "${var.cluster_identifier}-proxy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "rds.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "proxy" {
  count = local.is_primary ? 1 : 0

  name = "read-master-secret"
  role = aws_iam_role.proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = keys(local.proxy_auth_secrets)
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt"]
        Resource = aws_kms_key.master.arn
      }
    ]
  })
}

resource "aws_db_proxy" "this" {
  count = local.is_primary ? 1 : 0

  name                   = "${var.cluster_identifier}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.proxy[0].arn
  vpc_subnet_ids         = data.terraform_remote_state.network.outputs.rds_subnet_ids
  vpc_security_group_ids = [aws_security_group.proxy[0].id]
  require_tls            = true
  idle_client_timeout    = 1800

  dynamic "auth" {
    for_each = local.proxy_auth_secrets
    content {
      auth_scheme = "SECRETS"
      iam_auth    = "DISABLED"
      secret_arn  = auth.key
      description = auth.value
    }
  }
}

resource "aws_db_proxy_default_target_group" "this" {
  count = local.is_primary ? 1 : 0

  db_proxy_name = aws_db_proxy.this[0].name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "this" {
  count = local.is_primary ? 1 : 0

  db_proxy_name         = aws_db_proxy.this[0].name
  target_group_name     = aws_db_proxy_default_target_group.this[0].name
  db_cluster_identifier = module.aurora.cluster_id
}

resource "aws_db_proxy_endpoint" "reader" {
  count = local.is_primary ? 1 : 0

  db_proxy_name          = aws_db_proxy.this[0].name
  db_proxy_endpoint_name = "${var.cluster_identifier}-reader"
  vpc_subnet_ids         = data.terraform_remote_state.network.outputs.rds_subnet_ids
  vpc_security_group_ids = [aws_security_group.proxy[0].id]
  target_role            = "READ_ONLY"
}
