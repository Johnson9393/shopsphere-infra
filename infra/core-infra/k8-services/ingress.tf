resource "kubernetes_namespace" "app" {
  metadata {
    name = "${var.project_name}-${var.environment}"
  }
}

resource "kubernetes_ingress_v1" "shop" {
  depends_on = [helm_release.alb_controller, aws_acm_certificate_validation.env]

  metadata {
    name      = var.project_name
    namespace = kubernetes_namespace.app.metadata[0].name

    annotations = {
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/certificate-arn" = aws_acm_certificate.env.arn
      "alb.ingress.kubernetes.io/wafv2-acl-arn"   = aws_wafv2_web_acl.alb.arn
      "alb.ingress.kubernetes.io/group.name"      = "${var.environment}-${var.project_name}"
      "external-dns.alpha.kubernetes.io/hostname" = "origin.${var.environment}.${var.domain_name}"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "origin.${var.environment}.${var.domain_name}"

      http {
        path {
          path      = "/"
          path_type = "Prefix"

          backend {
            service {
              name = "api-gateway"

              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}
