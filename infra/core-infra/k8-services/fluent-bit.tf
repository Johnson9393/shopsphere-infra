resource "aws_iam_role" "fluent_bit" {
  name               = "${var.environment}-${var.project_name}-fluent-bit"
  assume_role_policy = local.pod_identity_assume
}

resource "aws_iam_role_policy" "fluent_bit" {
  name = "logs"
  role = aws_iam_role.fluent_bit.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
        ]
        Resource = "${aws_cloudwatch_log_group.application.arn}:*"
      }
    ]
  })
}

resource "aws_eks_pod_identity_association" "fluent_bit" {
  depends_on = [aws_eks_addon.pod_identity]

  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "fluent-bit"
  role_arn        = aws_iam_role.fluent_bit.arn
}

resource "helm_release" "fluent_bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.48.9"
  namespace  = "kube-system"

  values = [yamlencode({
    serviceAccount = {
      create = true
      name   = "fluent-bit"
    }
    config = {
      outputs = <<-EOT
        [OUTPUT]
            Name                cloudwatch_logs
            Match               *
            region              ${var.aws_region}
            log_group_name      ${aws_cloudwatch_log_group.application.name}
            log_stream_prefix   pod-
            auto_create_group   false
      EOT
    }
  })]
}
