# One PostgreSQL login per environment. Aurora manages only the master password.
# The bootstrap job in each cluster creates the role and grants it that
# environment's databases.
resource "random_password" "application" {
  for_each = var.environments

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "application" {
  for_each = var.environments

  name        = "${var.project_name}/${each.key}/aurora"
  description = "${each.key} database login. This user can reach only the ${each.key} databases."
  kms_key_id  = aws_kms_key.master.arn
}

resource "aws_secretsmanager_secret_version" "application" {
  for_each = var.environments

  secret_id = aws_secretsmanager_secret.application[each.key].id

  # RDS Proxy accepts these fields and ignores host, port, and dbname.
  secret_string = jsonencode({
    username = "shopsphere_${each.key}"
    password = random_password.application[each.key].result
    engine   = "postgres"
    host     = aws_db_proxy.this.endpoint
    port     = module.aurora.port
    dbname   = "${each.key}_products"
  })
}
