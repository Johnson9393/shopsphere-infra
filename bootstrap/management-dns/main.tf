provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Stack     = "management-dns"
    }
  }
}

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

resource "aws_iam_role" "dns" {
  name = "${var.project_name}-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = var.member_account_ids
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "dns" {
  name = "change-zone"
  role = aws_iam_role.dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:GetChange"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["route53:ChangeResourceRecordSets", "route53:ListResourceRecordSets"]
        Resource = data.aws_route53_zone.main.arn
      }
    ]
  })
}
