data "aws_iam_policy_document" "oidc_assume" {
  for_each = {
    external-secrets = "system:serviceaccount:external-secrets:external-secrets"
    alb-controller   = "system:serviceaccount:kube-system:aws-load-balancer-controller"
    autoscaler       = "system:serviceaccount:kube-system:cluster-autoscaler"
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.terraform_remote_state.eks.outputs.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_host}:sub"
      values   = [each.value]
    }
  }
}

resource "aws_iam_role" "external_secrets" {
  name               = "${var.environment}-${var.project_name}-external-secrets"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume["external-secrets"].json
}

resource "aws_iam_role_policy" "external_secrets" {
  name = "secrets"
  role = aws_iam_role.external_secrets.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Effect = "Allow"
          Action = [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
          ]
          Resource = [
            "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/${var.environment}/*",
            "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.project_name}/nonprod/*",
            "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:rds!*",
          ]
        }
      ],
      contains(["dev", "qa", "uat"], var.environment) ? [
        {
          Effect = "Allow"
          Action = [
            "kms:Decrypt",
            "kms:DescribeKey",
          ]
          Resource = "*"
          Condition = {
            "ForAnyValue:StringEquals" = {
              "kms:ResourceAliases" = "alias/nonprod-shopsphere-aurora"
            }
          }
        }
      ] : []
    )
  })
}

resource "aws_iam_role" "alb_controller" {
  name               = "${var.environment}-${var.project_name}-alb-controller"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume["alb-controller"].json
}

resource "aws_iam_role_policy" "alb_controller" {
  name = "alb"
  role = aws_iam_role.alb_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticloadbalancing:*",
          "ec2:Describe*",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "iam:CreateServiceLinkedRole",
          "cognito-idp:DescribeUserPoolClient",
          "acm:ListCertificates",
          "acm:DescribeCertificate",
          "wafv2:GetWebACL",
          "wafv2:GetWebACLForResource",
          "wafv2:AssociateWebACL",
          "wafv2:DisassociateWebACL",
          "shield:GetSubscriptionState",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "notification" {
  name = "${var.environment}-${var.project_name}-notification"

  assume_role_policy = local.pod_identity_assume
}

resource "aws_iam_role_policy" "notification" {
  name = "ses"
  role = aws_iam_role.notification.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role" "autoscaler" {
  name               = "${var.environment}-${var.project_name}-cluster-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.oidc_assume["autoscaler"].json
}

resource "aws_iam_role_policy" "autoscaler" {
  name = "scale"
  role = aws_iam_role.autoscaler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeImages",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions",
          "eks:DescribeNodegroup",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/k8s.io/cluster-autoscaler/enabled"               = "true"
            "aws:ResourceTag/k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
          }
        }
      }
    ]
  })
}
