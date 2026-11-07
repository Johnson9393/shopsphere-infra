# Primary only. Secondary inherits the user from the global cluster.
resource "random_password" "master" {
  count = local.is_primary ? 1 : 0

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Created only for preprod/prod primary. Non-prod leaves this off (regional HA only).
# Secondary module call in us-west-1 does not create this; it attaches to the id we output.
resource "aws_rds_global_cluster" "this" {
  count = var.create_global_cluster ? 1 : 0

  global_cluster_identifier = "${local.cluster_identifier}-global"
  engine                    = "aurora-postgresql"
  engine_version            = var.engine_version
  database_name             = var.database_name
  storage_encrypted         = true
}

resource "aws_rds_cluster" "this" {
  cluster_identifier = local.cluster_identifier
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version
  port               = var.port

  global_cluster_identifier = var.create_global_cluster ? aws_rds_global_cluster.this[0].id : var.global_cluster_identifier

  # Writer credentials exist only on the primary. Omitting them on the secondary
  # is how Aurora Global Database decides which regional cluster is the writer.
  database_name   = local.is_primary && !var.create_global_cluster ? var.database_name : null
  master_username = local.is_primary ? var.master_username : null
  master_password = local.is_primary ? random_password.master[0].result : null

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = var.skip_final_snapshot ? null : "${local.cluster_identifier}-final"
  deletion_protection          = var.deletion_protection
  apply_immediately            = var.apply_immediately

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  tags = local.tags

  lifecycle {
    precondition {
      condition     = !(var.create_global_cluster && var.is_global_secondary)
      error_message = "A cluster cannot be both the Global Database primary (create_global_cluster) and a secondary (is_global_secondary). Call this module twice: east primary, west secondary."
    }

    precondition {
      condition     = !var.is_global_secondary || (var.global_cluster_identifier != null && var.global_cluster_identifier != "")
      error_message = "is_global_secondary requires global_cluster_identifier from the primary module output."
    }
  }
}

# One instance per map entry. AWS picks the writer from promotion_tier (lowest wins).
resource "aws_rds_cluster_instance" "this" {
  for_each = var.instances

  identifier         = "${local.cluster_identifier}-${each.key}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = each.value.instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  promotion_tier     = each.value.promotion_tier

  publicly_accessible = false
  apply_immediately   = var.apply_immediately

  tags = merge(local.tags, {
    Name = "${local.cluster_identifier}-${each.key}"
    Role = each.key
  })
}
