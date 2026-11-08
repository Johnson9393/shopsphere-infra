data "aws_subnet" "application" {
  for_each = toset(flatten([
    for env in var.environments :
    data.terraform_remote_state.network.outputs.private_subnet_ids_by_environment[env]
  ]))
  id = each.value
}

locals {
  application_cidrs = [for subnet in data.aws_subnet.application : subnet.cidr_block]
}

resource "aws_security_group" "proxy" {
  name        = "${var.cluster_identifier}-proxy"
  description = "RDS Proxy from application private subnets"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description = "Postgres from application private subnets"
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
  type                     = "ingress"
  description              = "Postgres from RDS Proxy"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = module.aurora.security_group_id
  source_security_group_id = aws_security_group.proxy.id
}

resource "aws_iam_role" "proxy" {
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
  name = "read-master-secret"
  role = aws_iam_role.proxy.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = module.aurora.master_user_secret_arn
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
  name                   = "${var.cluster_identifier}-proxy"
  engine_family          = "POSTGRESQL"
  role_arn               = aws_iam_role.proxy.arn
  vpc_subnet_ids         = data.terraform_remote_state.network.outputs.rds_subnet_ids
  vpc_security_group_ids = [aws_security_group.proxy.id]
  require_tls            = true
  idle_client_timeout    = 1800

  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = module.aurora.master_user_secret_arn
  }
}

resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    max_connections_percent      = 90
    max_idle_connections_percent = 50
    connection_borrow_timeout    = 120
  }
}

resource "aws_db_proxy_target" "this" {
  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.this.name
  db_cluster_identifier = module.aurora.cluster_id
}

resource "aws_db_proxy_endpoint" "reader" {
  db_proxy_name          = aws_db_proxy.this.name
  db_proxy_endpoint_name = "${var.cluster_identifier}-reader"
  vpc_subnet_ids         = data.terraform_remote_state.network.outputs.rds_subnet_ids
  vpc_security_group_ids = [aws_security_group.proxy.id]
  target_role            = "READ_ONLY"
}
