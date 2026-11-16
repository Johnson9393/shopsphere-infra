resource "aws_eks_addon" "pod_identity" {
  cluster_name                = local.cluster_name
  addon_name                  = "eks-pod-identity-agent"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
}

resource "aws_eks_pod_identity_association" "external_dns" {
  depends_on = [aws_eks_addon.pod_identity]

  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "external-dns"
  role_arn        = aws_iam_role.external_dns.arn
}

resource "aws_eks_pod_identity_association" "cloudwatch" {
  depends_on = [aws_eks_addon.pod_identity]

  cluster_name    = local.cluster_name
  namespace       = "amazon-cloudwatch"
  service_account = "cloudwatch-agent"
  role_arn        = aws_iam_role.cloudwatch.arn
}

resource "aws_eks_pod_identity_association" "adot" {
  depends_on = [aws_eks_addon.pod_identity]

  cluster_name    = local.cluster_name
  namespace       = "kube-system"
  service_account = "adot-collector"
  role_arn        = aws_iam_role.adot.arn
}

resource "aws_eks_pod_identity_association" "cart" {
  depends_on = [aws_eks_addon.pod_identity, kubernetes_namespace.app]

  cluster_name    = local.cluster_name
  namespace       = kubernetes_namespace.app.metadata[0].name
  service_account = "cart-service"
  role_arn        = aws_iam_role.cart.arn
}

resource "aws_eks_pod_identity_association" "notification" {
  depends_on = [aws_eks_addon.pod_identity, kubernetes_namespace.app]

  cluster_name    = local.cluster_name
  namespace       = kubernetes_namespace.app.metadata[0].name
  service_account = "notification-service"
  role_arn        = aws_iam_role.notification.arn
}

resource "aws_eks_pod_identity_association" "order" {
  depends_on = [aws_eks_addon.pod_identity, kubernetes_namespace.app]

  cluster_name    = local.cluster_name
  namespace       = kubernetes_namespace.app.metadata[0].name
  service_account = "order-service"
  role_arn        = aws_iam_role.order.arn
}

resource "aws_eks_pod_identity_association" "payment" {
  depends_on = [aws_eks_addon.pod_identity, kubernetes_namespace.app]

  cluster_name    = local.cluster_name
  namespace       = kubernetes_namespace.app.metadata[0].name
  service_account = "payment-service"
  role_arn        = aws_iam_role.payment.arn
}

resource "aws_eks_pod_identity_association" "user" {
  depends_on = [aws_eks_addon.pod_identity, kubernetes_namespace.app]

  cluster_name    = local.cluster_name
  namespace       = kubernetes_namespace.app.metadata[0].name
  service_account = "user-service"
  role_arn        = aws_iam_role.user.arn
}
