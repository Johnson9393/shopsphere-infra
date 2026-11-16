resource "aws_cognito_user_pool" "shoppers" {
  name = "${var.environment}-${var.project_name}"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_user_pool_client" "shop" {
  name         = "${var.environment}-${var.project_name}-shop"
  user_pool_id = aws_cognito_user_pool.shoppers.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ]

  prevent_user_existence_errors = "ENABLED"
  access_token_validity         = 1
  id_token_validity             = 1
  refresh_token_validity        = 30

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}

resource "aws_secretsmanager_secret" "cognito" {
  name        = "${var.project_name}/${var.environment}/cognito"
  description = "Cognito user pool for ${var.environment}. No password is stored."
  kms_key_id  = aws_kms_key.data.arn
}

resource "aws_secretsmanager_secret_version" "cognito" {
  secret_id = aws_secretsmanager_secret.cognito.id
  secret_string = jsonencode({
    user_pool_id = aws_cognito_user_pool.shoppers.id
    client_id    = aws_cognito_user_pool_client.shop.id
    issuer       = "https://cognito-idp.${var.aws_region}.amazonaws.com/${aws_cognito_user_pool.shoppers.id}"
    region       = var.aws_region
  })
}
