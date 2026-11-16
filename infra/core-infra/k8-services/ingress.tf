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
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"        = "ip"
      "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/ssl-redirect"       = "443"
      "alb.ingress.kubernetes.io/certificate-arn"    = aws_acm_certificate.env.arn
      "alb.ingress.kubernetes.io/wafv2-acl-arn"      = aws_wafv2_web_acl.alb.arn
      "alb.ingress.kubernetes.io/group.name"         = "${var.environment}-${var.project_name}"
      "alb.ingress.kubernetes.io/load-balancer-name" = "${var.environment}-${var.project_name}"
      "alb.ingress.kubernetes.io/healthcheck-path"   = "/health"
      "external-dns.alpha.kubernetes.io/hostname"    = "origin.${var.environment}.${var.domain_name}"
    }
  }

  spec {
    ingress_class_name = "alb"

    rule {
      host = "origin.${var.environment}.${var.domain_name}"

      http {
        dynamic "path" {
          for_each = {
            products      = { path = "/api/v1/products", service = "product-service", port = 8001 }
            users         = { path = "/api/v1/users", service = "user-service", port = 8002 }
            cart          = { path = "/api/v1/cart", service = "cart-service", port = 8003 }
            orders        = { path = "/api/v1/orders", service = "order-service", port = 8004 }
            payments      = { path = "/api/v1/payments", service = "payment-service", port = 8005 }
            notifications = { path = "/api/v1/notifications", service = "notification-service", port = 8006 }
            frontend      = { path = "/", service = "frontend", port = 80 }
          }

          content {
            path      = path.value.path
            path_type = "Prefix"

            backend {
              service {
                name = path.value.service

                port {
                  number = path.value.port
                }
              }
            }
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
}
