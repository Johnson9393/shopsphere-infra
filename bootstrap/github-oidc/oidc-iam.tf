# Terraform role per environment.
# GitHub Actions in shopsphere-infra assumes this role to run plan/apply.

resource "aws_iam_role" "github_terraform" {
  for_each = var.environments

  name = "${var.terraform_role_name_prefix}-${each.value}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.terraform_oidc_subject
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_terraform_admin" {
  for_each = var.environments

  role       = aws_iam_role.github_terraform[each.value].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ECR push role per environment.
# GitHub Actions in shopsphere assumes this role to push images.

resource "aws_iam_role" "github_ecr" {
  for_each = var.environments

  name = "${var.ecr_role_name_prefix}-${each.value}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.ecr_oidc_subject
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "github_ecr" {
  for_each = var.environments

  name = "${var.ecr_role_name_prefix}-${each.value}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchCheckLayerAvailability",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
        ]
        Resource = local.ecr_repository_arn_patterns[each.value]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_ecr" {
  for_each = var.environments

  role       = aws_iam_role.github_ecr[each.value].name
  policy_arn = aws_iam_policy.github_ecr[each.value].arn
}
