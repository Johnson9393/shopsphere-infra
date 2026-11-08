module "eks" {
  source = "git::https://github.com/Johnson9393/aws-eks-module.git?ref=v1.0.0"

  env          = var.environment
  cluster_name = var.cluster_name

  cluster_version = var.cluster_version

  vpc_id             = data.terraform_remote_state.network.outputs.vpc_id
  private_subnet_ids = local.private_subnet_ids

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  public_access_cidrs     = var.public_access_cidrs

  enable_cluster_logs        = true
  cluster_encryption_enabled = true
  cluster_encryption_key_arn = aws_kms_key.eks_secrets.arn

  cluster_admin_role_arns = var.cluster_admin_role_arns

  eks_nodes = var.eks_nodes
  ami_type  = var.ami_type

  # These tags land on the managed node group and its Auto Scaling group.
  # Cluster Autoscaler discovers that node pool from the tags.
  default_tags = {
    Project                                         = var.project_name
    Environment                                     = var.environment
    Account                                         = var.account
    module_name                                     = "eks"
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }
}
