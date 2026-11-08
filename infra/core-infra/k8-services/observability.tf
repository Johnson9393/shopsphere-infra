resource "aws_iam_role" "cloudwatch" {
  name = "${var.environment}-${var.project_name}-cloudwatch"

  assume_role_policy = local.pod_identity_assume
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_xray" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_cloudwatch_log_group" "application" {
  name              = "/shopsphere/${var.environment}/application"
  retention_in_days = 30
}

resource "aws_eks_addon" "cloudwatch" {
  cluster_name                = local.cluster_name
  addon_name                  = "amazon-cloudwatch-observability"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_iam_role" "adot" {
  name = "${var.environment}-${var.project_name}-adot"

  assume_role_policy = local.pod_identity_assume
}

resource "aws_iam_role_policy_attachment" "adot_xray" {
  role       = aws_iam_role.adot.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "adot_cloudwatch" {
  role       = aws_iam_role.adot.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "helm_release" "adot" {
  name       = "adot-collector"
  repository = "https://open-telemetry.github.io/opentelemetry-helm-charts"
  chart      = "opentelemetry-collector"
  version    = "0.108.0"
  namespace  = "kube-system"

  values = [yamlencode({
    mode = "daemonset"
    serviceAccount = {
      create = true
      name   = "adot-collector"
    }
    image = {
      repository = "public.ecr.aws/aws-observability/aws-otel-collector"
    }
    config = {
      receivers = {
        otlp = {
          protocols = {
            http = {
              endpoint = "0.0.0.0:4318"
            }
          }
        }
      }
      exporters = {
        awsxray = {
          region = var.aws_region
        }
        awscloudwatchlogs = {
          region          = var.aws_region
          log_group_name  = aws_cloudwatch_log_group.application.name
          log_stream_name = "otel"
        }
      }
      service = {
        pipelines = {
          traces = {
            receivers = ["otlp"]
            exporters = ["awsxray"]
          }
          logs = {
            receivers = ["otlp"]
            exporters = ["awscloudwatchlogs"]
          }
        }
      }
    }
  })]
}

resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${var.environment}-application-errors"
  log_group_name = aws_cloudwatch_log_group.application.name
  pattern        = "ERROR"

  metric_transformation {
    name          = "ApplicationErrors"
    namespace     = "ShopSphere/${var.environment}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${var.environment}-shopsphere-application-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApplicationErrors"
  namespace           = "ShopSphere/${var.environment}"
  period              = 300
  statistic           = "Sum"
  threshold           = 20
  alarm_description   = "Application error lines in CloudWatch Logs"
  treat_missing_data  = "notBreaching"
}

resource "aws_cloudwatch_dashboard" "shop" {
  dashboard_name = "${var.environment}-shopsphere"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "log"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title  = "Application errors"
          query  = "SOURCE '${aws_cloudwatch_log_group.application.name}' | fields @timestamp, @message | filter @message like /ERROR/ | sort @timestamp desc | limit 50"
          region = var.aws_region
          view   = "table"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Pod CPU"
          region = var.aws_region
          view   = "timeSeries"
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", local.cluster_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Pod memory"
          region = var.aws_region
          view   = "timeSeries"
          metrics = [
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", local.cluster_name]
          ]
        }
      }
    ]
  })
}
