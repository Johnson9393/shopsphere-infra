# IAM role for managed node group to manage aws resources
resource "aws_iam_role" "eks_node" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.default_tags
}

# Three different common policies we attach to node group for NODE-> EKS Communication
# EKS CNI Policy to allow the node group VPC CNI plugin to manage ENIs and IP addresses for pods.
# Container Registry Read Only Policy to allow the node group to pull container images from Amazon ECR.
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_read_only" {
  role       = aws_iam_role.eks_node.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "main" {
  for_each = var.eks_nodes

  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${each.key}"

  node_role_arn = aws_iam_role.eks_node.arn
  subnet_ids    = var.private_subnet_ids

  version = each.value.kubernetes_version

  capacity_type  = "ON_DEMAND"
  instance_types = [each.value.instance_type]
  ami_type       = var.ami_type
  disk_size      = 50

  scaling_config {
    desired_size = each.value.desired_size
    min_size     = each.value.min_size
    max_size     = each.value.max_size
  }

  # It gives control over how many nodes can be unavilable during node updates rather taking all nodes down at once.
  update_config {
    max_unavailable = 1
  }

  tags = var.default_tags

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only,
    aws_eks_addon.vpc_cni
  ]
}
