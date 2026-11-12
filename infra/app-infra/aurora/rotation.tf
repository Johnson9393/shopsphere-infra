resource "aws_security_group" "rotation" {
  count = local.is_primary ? 1 : 0

  name        = "${var.cluster_identifier}-rotation"
  description = "Password rotation function"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  egress {
    description = "Secrets Manager and KMS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Aurora"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
  }
}

data "archive_file" "rotation" {
  count = local.is_primary ? 1 : 0

  type        = "zip"
  source_dir  = "${path.module}/rotation"
  output_path = "${path.module}/rotation.zip"
  excludes    = ["__pycache__", "*.pyc"]
}

resource "aws_iam_role" "rotation" {
  count = local.is_primary ? 1 : 0

  name = "${var.cluster_identifier}-rotation"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "rotation" {
  count = local.is_primary ? 1 : 0

  name = "rotate"
  role = aws_iam_role.rotation[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecretVersionStage",
        ]
        Resource = compact([
          module.aurora.master_user_secret_arn,
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/*",
        ])
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = aws_kms_key.master.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_function" "rotation" {
  count = local.is_primary ? 1 : 0

  function_name    = "${var.cluster_identifier}-rotate-db-password"
  role             = aws_iam_role.rotation[0].arn
  runtime          = "python3.12"
  handler          = "app.handler"
  timeout          = 60
  memory_size      = 256
  filename         = data.archive_file.rotation[0].output_path
  source_code_hash = data.archive_file.rotation[0].output_base64sha256

  vpc_config {
    subnet_ids         = data.terraform_remote_state.network.outputs.private_subnet_ids_by_environment[tolist(var.environments)[0]]
    security_group_ids = [aws_security_group.rotation[0].id]
  }

  environment {
    variables = {
      MASTER_SECRET_ARN = module.aurora.master_user_secret_arn
    }
  }
}

resource "aws_lambda_permission" "rotation" {
  count = local.is_primary ? 1 : 0

  statement_id  = "AllowSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation[0].function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "application" {
  for_each = aws_secretsmanager_secret.application

  secret_id           = each.value.id
  rotation_lambda_arn = aws_lambda_function.rotation[0].arn

  rotation_rules {
    automatically_after_days = 30
  }

  depends_on = [aws_lambda_permission.rotation]
}
