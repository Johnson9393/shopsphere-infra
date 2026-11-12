resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = "0.14.2"
  namespace        = "external-secrets"
  create_namespace = true

  values = [yamlencode({
    installCRDs = true
    serviceAccount = {
      name = "external-secrets"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.external_secrets.arn
      }
    }
    extraObjects = [
      {
        apiVersion = "external-secrets.io/v1"
        kind       = "ClusterSecretStore"
        metadata = {
          name = var.project_name
        }
        spec = {
          provider = {
            aws = {
              service = "SecretsManager"
              region  = var.aws_region
              auth = {
                jwt = {
                  serviceAccountRef = {
                    name      = "external-secrets"
                    namespace = "external-secrets"
                  }
                }
              }
            }
          }
        }
      }
    ]
  })]
}

resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  version    = "1.11.0"
  namespace  = "kube-system"

  values = [yamlencode({
    clusterName = local.cluster_name
    region      = var.aws_region
    vpcId       = data.aws_eks_cluster.this.vpc_config[0].vpc_id
    serviceAccount = {
      name = "aws-load-balancer-controller"
      annotations = {
        "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
      }
    }
  })]
}

resource "helm_release" "cluster_autoscaler" {
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler_chart_version
  namespace  = "kube-system"

  values = [yamlencode({
    autoDiscovery = {
      clusterName = local.cluster_name
    }
    awsRegion = var.aws_region
    rbac = {
      serviceAccount = {
        name = "cluster-autoscaler"
        annotations = {
          "eks.amazonaws.com/role-arn" = aws_iam_role.autoscaler.arn
        }
      }
    }
  })]
}

resource "helm_release" "reloader" {
  name             = "reloader"
  repository       = "https://stakater.github.io/stakater-charts"
  chart            = "reloader"
  version          = "1.2.1"
  namespace        = "kube-system"
  create_namespace = false
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = "7.8.5"
  namespace        = "${var.environment}-argocd"
  create_namespace = true

  values = [yamlencode({
    extraObjects = [
      {
        apiVersion = "argoproj.io/v1alpha1"
        kind       = "Application"
        metadata = {
          name      = "${var.project_name}-${var.environment}"
          namespace = "${var.environment}-argocd"
        }
        spec = {
          project = "default"
          source = {
            repoURL        = var.git_repo_url
            targetRevision = "main"
            path           = "apps/${var.environment}"
            directory = {
              recurse = true
            }
          }
          destination = {
            server    = "https://kubernetes.default.svc"
            namespace = "${var.environment}-argocd"
          }
          syncPolicy = {
            automated = {
              prune    = true
              selfHeal = true
            }
          }
        }
      }
    ]
  })]
}
