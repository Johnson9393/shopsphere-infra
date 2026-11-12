resource "aws_eks_addon" "ebs_csi" {
  cluster_name                = local.cluster_name
  addon_name                  = "aws-ebs-csi-driver"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "kubernetes_storage_class_v1" "gp3" {
  metadata {
    name = "gp3"

    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }

  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Delete"
  volume_binding_mode = "WaitForFirstConsumer"

  parameters = {
    type      = "gp3"
    encrypted = "true"
  }

  depends_on = [aws_eks_addon.ebs_csi]
}

resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server"
  chart      = "metrics-server"
  version    = "3.12.2"
  namespace  = "kube-system"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "monitoring"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "93.2.2"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  timeout = 900

  values = [yamlencode({
    fullnameOverride = "monitoring"
    kubeEtcd = {
      enabled = false
    }
    kubeControllerManager = {
      enabled = false
    }
    kubeScheduler = {
      enabled = false
    }
    grafana = {
      service = {
        port = 80
      }
      grafana.ini = {
        server = {
          domain              = "grafana.${var.environment}.${var.domain_name}"
          root_url            = "https://grafana.${var.environment}.${var.domain_name}"
          serve_from_sub_path = false
        }
      }
      additionalDataSources = [
        {
          name   = "Loki"
          type   = "loki"
          access = "proxy"
          url    = "http://loki-gateway.monitoring.svc.cluster.local"
        }
      ]
    }
    prometheus = {
      prometheusSpec = {
        retention = "2d"
        resources = {
          requests = {
            cpu    = "100m"
            memory = "400Mi"
          }
          limits = {
            memory = "1Gi"
          }
        }
        storageSpec = {
          volumeClaimTemplate = {
            spec = {
              storageClassName = kubernetes_storage_class_v1.gp3.metadata[0].name
              accessModes      = ["ReadWriteOnce"]
              resources = {
                requests = {
                  storage = "10Gi"
                }
              }
            }
          }
        }
      }
    }
    alertmanager = {
      alertmanagerSpec = {
        resources = {
          requests = {
            cpu    = "25m"
            memory = "64Mi"
          }
        }
      }
    }
  })]

  depends_on = [kubernetes_storage_class_v1.gp3]
}

resource "helm_release" "loki" {
  name       = "loki"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki"
  version    = "7.6.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  timeout = 600

  values = [yamlencode({
    deploymentMode = "SingleBinary"
    lokiCanary = {
      enabled = false
    }
    loki = {
      auth_enabled = false
      commonConfig = {
        replication_factor = 1
      }
      storage = {
        type = "filesystem"
      }
      schemaConfig = {
        configs = [
          {
            from         = "2024-04-01"
            store        = "tsdb"
            object_store = "filesystem"
            schema       = "v13"
            index = {
              prefix = "loki_index_"
              period = "24h"
            }
          }
        ]
      }
    }
    singleBinary = {
      replicas = 1
      persistence = {
        storageClass = kubernetes_storage_class_v1.gp3.metadata[0].name
        size         = "10Gi"
      }
    }
    read = {
      replicas = 0
    }
    write = {
      replicas = 0
    }
    backend = {
      replicas = 0
    }
    chunksCache = {
      enabled = false
    }
    resultsCache = {
      enabled = false
    }
    gateway = {
      enabled = true
    }
  })]

  depends_on = [kubernetes_storage_class_v1.gp3]
}

resource "helm_release" "promtail" {
  name       = "promtail"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "promtail"
  version    = "6.17.1"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [yamlencode({
    config = {
      clients = [
        {
          url = "http://loki-gateway.monitoring.svc.cluster.local/loki/api/v1/push"
        }
      ]
    }
  })]

  depends_on = [helm_release.loki]
}
