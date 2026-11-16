# One PostgreSQL login per environment. Aurora manages the master password.
# Terraform creates the secret names only. The rotation Lambda generates the
# application password, creates the role and databases, and writes Secrets Manager.
# State never contains that password.

resource "aws_secretsmanager_secret" "application" {
  for_each = toset(local.is_primary ? tolist(var.environments) : [])

  name        = "${var.project_name}/${each.key}/aurora"
  description = "${each.key} database login. The password is written by the rotation Lambda."
  kms_key_id  = aws_kms_key.master.arn
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
  description = "${each.value.service} database login for ${each.value.env}. The password is written by the rotation Lambda."
  kms_key_id  = aws_kms_key.master.arn
}
