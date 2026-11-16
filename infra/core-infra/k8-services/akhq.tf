resource "aws_iam_role" "akhq" {
  name               = "${var.environment}-${var.project_name}-akhq"
  assume_role_policy = local.pod_identity_assume
}

resource "aws_iam_role_policy" "akhq" {
  name   = "kafka"
  role   = aws_iam_role.akhq.id
  policy = local.kafka_client_policy
}

resource "aws_eks_pod_identity_association" "akhq" {
  depends_on = [aws_eks_addon.pod_identity, kubernetes_namespace.app]

  cluster_name    = local.cluster_name
  namespace       = kubernetes_namespace.app.metadata[0].name
  service_account = "akhq"
  role_arn        = aws_iam_role.akhq.arn
}

resource "kubernetes_service_account_v1" "akhq" {
  metadata {
    name      = "akhq"
    namespace = kubernetes_namespace.app.metadata[0].name
  }
}

resource "kubernetes_manifest" "akhq_secret" {
  depends_on = [helm_release.external_secrets]

  manifest = {
    apiVersion = "external-secrets.io/v1"
    kind       = "ExternalSecret"
    metadata = {
      name      = "akhq-kafka"
      namespace = kubernetes_namespace.app.metadata[0].name
    }
    spec = {
      refreshInterval = "1h"
      secretStoreRef = {
        kind = "ClusterSecretStore"
        name = "shopsphere"
      }
      target = {
        name = "akhq-kafka"
      }
      data = [
        {
          secretKey = "bootstrap"
          remoteRef = {
            key      = "${var.project_name}/${var.environment}/kafka"
            property = "bootstrap_brokers"
          }
        }
      ]
    }
  }
}

resource "kubernetes_config_map_v1" "akhq" {
  metadata {
    name      = "akhq"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    application.yml = <<-YAML
      akhq:
        connections:
          shopsphere:
            properties:
              bootstrap.servers: $${BOOTSTRAP_SERVERS}
              security.protocol: SASL_SSL
              sasl.mechanism: AWS_MSK_IAM
              sasl.jaas.config: software.amazon.msk.auth.iam.IAMLoginModule required;
              sasl.client.callback.handler.class: software.amazon.msk.auth.iam.IAMClientCallbackHandler
    YAML
  }
}

resource "kubernetes_deployment_v1" "akhq" {
  metadata {
    name      = "akhq"
    namespace = kubernetes_namespace.app.metadata[0].name
    labels = {
      app = "akhq"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "akhq"
      }
    }

    template {
      metadata {
        labels = {
          app = "akhq"
        }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.akhq.metadata[0].name

        container {
          name  = "akhq"
          image = "tchiotludo/akhq:0.25.1"

          port {
            container_port = 8080
          }

          env {
            name = "BOOTSTRAP_SERVERS"
            value_from {
              secret_key_ref {
                name = "akhq-kafka"
                key  = "bootstrap"
              }
            }
          }

          env {
            name  = "AKHQ_CONFIGURATION"
            value = kubernetes_config_map_v1.akhq.data["application.yml"]
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "akhq" {
  metadata {
    name      = "akhq"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  spec {
    selector = {
      app = "akhq"
    }

    port {
      port        = 80
      target_port = 8080
    }
  }
}
