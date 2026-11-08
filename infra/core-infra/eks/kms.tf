resource "aws_kms_key" "eks_secrets" {
  description         = "Encrypts Kubernetes secrets for ${var.cluster_name}"
  enable_key_rotation = true

  tags = {
    Name = "${var.cluster_name}-secrets"
  }
}

resource "aws_kms_alias" "eks_secrets" {
  name          = "alias/${var.cluster_name}-secrets"
  target_key_id = aws_kms_key.eks_secrets.key_id
}
