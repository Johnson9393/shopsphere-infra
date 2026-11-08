data "aws_caller_identity" "current" {}

data "terraform_remote_state" "eks" {
  backend = "s3"

  config = {
    bucket = var.state_bucket
    key    = var.eks_state_key
    region = var.aws_region
  }
}

data "aws_eks_cluster" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.eks.outputs.cluster_name
}

locals {
  oidc_host    = replace(data.terraform_remote_state.eks.outputs.cluster_oidc_issuer_url, "https://", "")
  cluster_name = data.terraform_remote_state.eks.outputs.cluster_name

  # Pod Identity trust. The association, not an OIDC subject, decides which service account can use the role.
  pod_identity_assume = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession",
        ]
      }
    ]
  })
}
