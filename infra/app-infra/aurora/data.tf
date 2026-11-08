data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.network_state_bucket
    key    = var.network_state_key
    region = var.aws_region
  }
}

data "aws_eks_cluster" "allowed" {
  for_each = local.eks_cluster_names
  name     = each.value
}

locals {
  # Several environments share one cluster in non-prod, so the name is the account.
  # Pre-prod and prod each pass one environment, and that name is the cluster.
  cluster_env = length(var.environments) == 1 ? tolist(var.environments)[0] : var.account

  eks_cluster_names = toset([
    for env in var.environments : "${env}-${var.project_name}"
  ])

  eks_security_group_ids = [
    for cluster in data.aws_eks_cluster.allowed : cluster.vpc_config[0].cluster_security_group_id
  ]
}
