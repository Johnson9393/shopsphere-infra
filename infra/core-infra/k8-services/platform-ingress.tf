locals {
  platform_ingress_annotations = {
    "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
    "alb.ingress.kubernetes.io/target-type"     = "ip"
    "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
    "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
    "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.env.arn
    "alb.ingress.kubernetes.io/wafv2-acl-arn"   = aws_wafv2_web_acl.alb.arn
    "alb.ingress.kubernetes.io/group.name"      = "${var.environment}-${var.project_name}"
  }

  platform_endpoints = {
    argocd = {
      namespace = "${var.environment}-argocd"
      service   = "argocd-server"
      port      = 80
      health    = "/healthz"
    }
    grafana = {
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      service   = "monitoring-grafana"
      port      = 80
      health    = "/api/health"
    }
    prometheus = {
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      service   = "monitoring-prometheus"
      port      = 9090
      health    = "/-/healthy"
    }
    loki = {
      namespace = kubernetes_namespace.monitoring.metadata[0].name
      service   = "loki-gateway"
      port      = 80
      health    = "/loki/api/v1/status/buildinfo"
    }
  }
}

resource "kubernetes_ingress_v1" "platform" {
  for_each = local.platform_endpoints

  metadata {
    name      = each.key
    namespace = each.value.namespace

    annotations = merge(local.platform_ingress_annotations, {
      "alb.ingress.kubernetes.io/healthcheck-path" = each.value.health
      "external-dns.alpha.kubernetes.io/hostname"  = "${each.key}.${var.environment}.${var.domain_name}"
    })
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "${each.key}.${var.environment}.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = each.value.service

              port {
                number = each.value.port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.alb_controller,
    helm_release.argocd,
    helm_release.external_dns,
    helm_release.kube_prometheus_stack,
    helm_release.loki,
    aws_acm_certificate_validation.env,
  ]
}
