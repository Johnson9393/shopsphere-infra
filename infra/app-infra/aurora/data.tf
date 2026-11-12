data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.network_state_bucket
    key    = var.network_state_key
    region = var.state_region
  }
}

data "terraform_remote_state" "primary" {
  count   = var.is_global_secondary ? 1 : 0
  backend = "s3"

  config = {
    bucket = var.network_state_bucket
    key    = var.primary_state_key
    region = var.state_region
  }
}

data "aws_eks_clusters" "account" {}

locals {
  # Several environments share one cluster in non-prod, so the name is the account.
  # Pre-prod and prod each pass one environment, and that name is the cluster.
  cluster_env = length(var.environments) == 1 ? tolist(var.environments)[0] : var.account
  is_primary  = !var.is_global_secondary

  eks_cluster_names = toset([
    for env in var.environments : "${env}-${var.project_name}"
  ])

  # A dev run creates the dev cluster in the same workflow, after this plan.
  # Missing qa and uat clusters are added on their own later runs.
  existing_eks_cluster_names = setintersection(local.eks_cluster_names, toset(data.aws_eks_clusters.account.names))

  eks_security_group_ids = [
    for cluster in data.aws_eks_cluster.allowed : cluster.vpc_config[0].cluster_security_group_id
  ]
}

data "aws_eks_cluster" "allowed" {
  for_each = local.existing_eks_cluster_names
  name     = each.value
}
