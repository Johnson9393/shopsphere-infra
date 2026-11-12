data "archive_file" "rotation" {
  type        = "zip"
  source_dir  = "${path.module}/rotation"
  output_path = "${path.module}/rotation.zip"
}

resource "aws_security_group" "rotation" {
  name        = "${var.environment}-${var.project_name}-rotation"
  description = "Password rotation function"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  egress {
    description = "AWS APIs and the RabbitMQ console"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "rotation" {
  name = "${var.environment}-${var.project_name}-rotation"

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
  name = "rotate"
  role = aws_iam_role.rotation.id

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
        Resource = "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["kms:Decrypt", "kms:GenerateDataKey", "kms:DescribeKey"]
        Resource = aws_kms_key.data.arn
      },
      {
        Effect   = "Allow"
        Action   = ["elasticache:ModifyReplicationGroup"]
        Resource = "*"
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
  function_name    = "${var.environment}-${var.project_name}-rotate-password"
  role             = aws_iam_role.rotation.arn
  runtime          = "python3.12"
  handler          = "app.handler"
  timeout          = 60
  memory_size      = 256
  filename         = data.archive_file.rotation.output_path
  source_code_hash = data.archive_file.rotation.output_base64sha256

  vpc_config {
    subnet_ids         = local.private_subnet_ids
    security_group_ids = [aws_security_group.rotation.id]
  }
}

resource "aws_lambda_permission" "rotation" {
  statement_id  = "AllowSecretsManager"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rotation.function_name
  principal     = "secretsmanager.amazonaws.com"
}

resource "aws_secretsmanager_secret_rotation" "passwords" {
  for_each = {
    elasticache = aws_secretsmanager_secret.redis.id
    amazonmq    = aws_secretsmanager_secret.mq.id
    application = aws_secretsmanager_secret.application.id
  }

  secret_id           = each.value
  rotation_lambda_arn = aws_lambda_function.rotation.arn

  rotation_rules {
    automatically_after_days = 7
  }

  depends_on = [aws_lambda_permission.rotation]
}
