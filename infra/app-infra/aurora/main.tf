module "aurora" {
  source = "git::https://github.com/Johnson9393/aws-aurora-module.git?ref=v1.1.0"

  env                = local.cluster_env
  cluster_identifier = var.cluster_identifier

  engine_version                = var.engine_version
  database_name                 = var.database_name
  master_username               = var.master_username
  master_user_secret_kms_key_id = local.is_primary ? aws_kms_key.master.arn : null
  kms_key_arn                   = aws_kms_key.master.arn

  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  rds_subnet_ids             = data.terraform_remote_state.network.outputs.rds_subnet_ids
  allowed_security_group_ids = concat(local.eks_security_group_ids, local.is_primary ? [aws_security_group.rotation[0].id] : [])
  allowed_cidr_blocks        = local.is_primary ? [] : local.application_cidrs

  instances = var.instances

  create_global_cluster     = var.create_global_cluster
  is_global_secondary       = var.is_global_secondary
  global_cluster_identifier = local.is_primary ? null : data.terraform_remote_state.primary[0].outputs.global_cluster_id

  backup_retention_period = var.backup_retention_period
  skip_final_snapshot     = var.skip_final_snapshot
  deletion_protection     = var.deletion_protection

  default_tags = {
    Project     = var.project_name
    Account     = var.account
    Environment = local.cluster_env
    module_name = "aurora"
  }
}

resource "aws_secretsmanager_secret" "connection" {
  count = local.is_primary ? 1 : 0

  name        = "${var.project_name}/${local.cluster_env}/aurora-connection"
  description = "Aurora endpoints for ${var.cluster_identifier}. The password stays in the Aurora-managed secret."
}

resource "aws_secretsmanager_secret_version" "connection" {
  count = local.is_primary ? 1 : 0

  secret_id = aws_secretsmanager_secret.connection[0].id

  secret_string = jsonencode({
    host     = aws_db_proxy.this[0].endpoint
    reader   = aws_db_proxy_endpoint.reader[0].endpoint
    port     = tostring(module.aurora.port)
    username = module.aurora.master_username
    dbname   = module.aurora.database_name
  })
}
