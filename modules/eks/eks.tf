resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.cluster_version

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = var.private_subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs     = var.public_access_cidrs

  }

    # Create service ipv4 cidr for kubernetes services, if not provided, default will be used
    # Dynmaic block we used cuz of it is optional, if not provided, block won't be created. 
  dynamic "kubernetes_network_config" {
    for_each = var.cluster_service_ipv4_cidr != null ? [1] : []

    content {
      service_ipv4_cidr = var.cluster_service_ipv4_cidr
    }
  }

  enabled_cluster_log_types = var.enable_cluster_logs ? var.cluster_log_types : []

    # K8 secrets stored in etcd are encrypted at rest using envelope encryption. This requires a KMS key ARN to be provided for the encryption.
  dynamic "encryption_config" {
    for_each = var.cluster_encryption_enabled ? [1] : []

    content {
      provider {
        key_arn = var.cluster_encryption_key_arn
      }

      resources = ["secrets"]
    }
  }

  tags = var.default_tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# Here toset() converts list into a set and it will not allow duplicates.
# EKS access entry is used to grant access to EKS cluster for specific IAM role or users. 
resource "aws_eks_access_entry" "cluster_admins" {
  for_each = toset(var.cluster_admin_role_arns)

  cluster_name  = aws_eks_cluster.main.name
  principal_arn = each.value
  type          = "STANDARD"
}

# For the specific access entry IAM role providing permissions to perform actions on eks. 
resource "aws_eks_access_policy_association" "cluster_admins" {
  for_each = toset(var.cluster_admin_role_arns)

  cluster_name  = aws_eks_access_entry.cluster_admins[each.value].cluster_name
  principal_arn = aws_eks_access_entry.cluster_admins[each.value].principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}