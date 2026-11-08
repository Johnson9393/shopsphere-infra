module "aurora" {
  source = "git::https://github.com/Johnson9393/aws-aurora-module.git?ref=v1.1.0"

  env                = local.cluster_env
  cluster_identifier = var.cluster_identifier

  engine_version                = var.engine_version
  database_name                 = var.database_name
  master_username               = var.master_username
  master_user_secret_kms_key_id = aws_kms_key.master.arn

  vpc_id                     = data.terraform_remote_state.network.outputs.vpc_id
  rds_subnet_ids             = data.terraform_remote_state.network.outputs.rds_subnet_ids
  allowed_security_group_ids = local.eks_security_group_ids

  instances = var.instances

  create_global_cluster = var.create_global_cluster

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
