# One PostgreSQL login per environment. Aurora manages only the master password.
# The bootstrap job in each cluster creates the role and grants it that
# environment's databases.
resource "random_password" "application" {
  for_each = toset(local.is_primary ? tolist(var.environments) : [])

  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "application" {
  for_each = toset(local.is_primary ? tolist(var.environments) : [])

  name        = "${var.project_name}/${each.key}/aurora"
  description = "${each.key} database login. This user can reach only the ${each.key} databases."
  kms_key_id  = aws_kms_key.master.arn
}

resource "aws_secretsmanager_secret_version" "application" {
  for_each = toset(local.is_primary ? tolist(var.environments) : [])

  secret_id = aws_secretsmanager_secret.application[each.key].id

  lifecycle {
    ignore_changes = [secret_string]
  }

  # RDS Proxy accepts these fields and ignores host, port, and dbname.
  secret_string = jsonencode({
    username = "shopsphere_${each.key}"
    password = random_password.application[each.key].result
    engine   = "postgres"
    host     = aws_db_proxy.this[0].endpoint
    port     = module.aurora.port
    dbname   = "${each.key}_products"
  })
}

locals {
  service_databases = local.is_primary ? {
    "product-service" = "products"
    "user-service"    = "users"
    "order-service"   = "orders"
    "payment-service" = "payments"
  } : {}
}

resource "aws_secretsmanager_secret" "service" {
  for_each = {
    for item in setproduct(tolist(var.environments), keys(local.service_databases)) :
    "${item[0]}/${item[1]}" => {
      env      = item[0]
      service  = item[1]
      database = local.service_databases[item[1]]
    }
    if local.is_primary
  }

  name        = "${var.project_name}/${each.value.env}/${each.value.service}"
  description = "${each.value.service} database login for ${each.value.env}."
  kms_key_id  = aws_kms_key.master.arn
}

resource "aws_secretsmanager_secret_version" "service" {
  for_each = aws_secretsmanager_secret.service

  secret_id = each.value.id

  lifecycle {
    ignore_changes = [secret_string]
  }
  secret_string = jsonencode({
    username = "shopsphere_${split("/", each.key)[0]}"
    password = random_password.application[split("/", each.key)[0]].result
    engine   = "postgres"
    host     = aws_db_proxy.this[0].endpoint
    port     = module.aurora.port
    dbname   = "${split("/", each.key)[0]}_${local.service_databases[split("/", each.key)[1]]}"
  })
}
