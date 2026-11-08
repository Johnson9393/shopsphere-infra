resource "aws_kms_key" "master" {
  description             = "Encrypts the Aurora master password for ${var.cluster_identifier}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow account administration"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Secrets Manager to encrypt the master password"
        Effect = "Allow"
        Principal = {
          Service = "secretsmanager.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey",
          "kms:CreateGrant",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${var.aws_region}.amazonaws.com"
          }
        }
      },
    ]
  })

  tags = {
    Name = "${var.cluster_identifier}-aurora"
  }

  lifecycle {
    precondition {
      condition     = var.account == "nonprod" || length(var.environments) == 1
      error_message = "Preprod and prod each get their own Aurora cluster. Pass one environment."
    }

    precondition {
      condition     = var.account == "prod" || !var.create_global_cluster
      error_message = "Aurora Global Database is for preprod and prod. Leave it off for the shared non-prod cluster."
    }
  }
}

resource "aws_kms_alias" "master" {
  name          = "alias/${var.cluster_identifier}-aurora"
  target_key_id = aws_kms_key.master.key_id
}
