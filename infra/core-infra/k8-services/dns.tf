data "aws_route53_zone" "main" {
  provider = aws.dns

  name         = var.domain_name
  private_zone = false
}

resource "aws_acm_certificate" "env" {
  domain_name       = "*.${var.environment}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.environment}-${var.project_name}-wildcard"
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.dns

  for_each = {
    for dvo in aws_acm_certificate.env.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 60
  records         = [each.value.record]
}

resource "aws_acm_certificate_validation" "env" {
  certificate_arn         = aws_acm_certificate.env.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

resource "aws_iam_role" "external_dns" {
  name = "${var.environment}-${var.project_name}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = data.terraform_remote_state.eks.outputs.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${local.oidc_host}:aud" = "sts.amazonaws.com"
            "${local.oidc_host}:sub" = "system:serviceaccount:kube-system:external-dns"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "external_dns" {
  name = "assume-management-dns"
  role = aws_iam_role.external_dns.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.dns_assume_role_arn
      }
    ]
  })
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns"
  chart      = "external-dns"
  version    = "1.15.2"
  namespace  = "kube-system"

  values = [yamlencode({
    provider      = "aws"
    policy        = "sync"
    domainFilters = [var.domain_name]
    txtOwnerId    = "${var.environment}-${var.project_name}"
    extraArgs = [
      "--aws-zone-type=public",
      "--aws-assume-role=${var.dns_assume_role_arn}",
    ]
    serviceAccount = {
      create = true
      name   = "external-dns"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.external_dns.arn
      }
    }
  })]
}
