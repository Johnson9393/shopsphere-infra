# OIDC issuer associated with this EKS cluster
locals {
  oidc_issuer_url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# Dedicated IAM OIDC provider for the EKS cluster
resource "aws_iam_openid_connect_provider" "this" {
  url = local.oidc_issuer_url

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = {
    Name        = "${var.env}-shopsphere-eks-oidc"
    Environment = var.env
    Project     = "shopsphere"
    ManagedBy   = "Terraform"
  }
}