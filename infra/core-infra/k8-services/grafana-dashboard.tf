resource "kubernetes_config_map_v1" "grafana_dashboard" {
  metadata {
    name      = "shopsphere-services"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "shopsphere.json" = jsonencode({
      title         = "ShopSphere services"
      uid           = "shopsphere-services"
      schemaVersion = 39
      tags          = ["shopsphere"]
      timezone      = "browser"
      panels = [
        {
          type    = "timeseries"
          title   = "Pod restarts"
          gridPos = { h = 8, w = 12, x = 0, y = 0 }
          targets = [
            {
              expr         = "sum by (pod) (kube_pod_container_status_restarts_total{namespace=~\"shopsphere-.*\"})"
              legendFormat = "{{pod}}"
            }
          ]
        },
        {
          type    = "timeseries"
          title   = "CPU by pod"
          gridPos = { h = 8, w = 12, x = 12, y = 0 }
          targets = [
            {
              expr         = "sum by (pod) (rate(container_cpu_usage_seconds_total{namespace=~\"shopsphere-.*\",container!=\"\"}[5m]))"
              legendFormat = "{{pod}}"
            }
          ]
        },
        {
          type    = "timeseries"
          title   = "Memory by pod"
          gridPos = { h = 8, w = 24, x = 0, y = 8 }
          targets = [
            {
              expr         = "sum by (pod) (container_memory_working_set_bytes{namespace=~\"shopsphere-.*\",container!=\"\"})"
              legendFormat = "{{pod}}"
            }
          ]
        }
      ]
    })
  }

  depends_on = [helm_release.kube_prometheus_stack]
}
