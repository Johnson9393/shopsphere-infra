resource "aws_db_subnet_group" "this" {
  name        = "${local.cluster_identifier}-db"
  description = "Private RDS subnets for ${local.cluster_identifier}"
  subnet_ids  = var.rds_subnet_ids

  tags = merge(local.tags, {
    Name = "${local.cluster_identifier}-db"
  })
}

# Ingress is separate rules so non-prod can pass three EKS cluster SGs
# (dev, qa, uat) without rebuilding the group.
resource "aws_security_group" "this" {
  name        = "${local.cluster_identifier}-rds"
  description = "Postgres to ${local.cluster_identifier} from allowed EKS / VPN only"
  vpc_id      = var.vpc_id

  egress {
    description = "Aurora outbound (backups, AWS APIs)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${local.cluster_identifier}-rds"
  })
}

resource "aws_security_group_rule" "from_eks" {
  for_each = toset(var.allowed_security_group_ids)

  type                     = "ingress"
  description              = "Postgres from EKS ${each.value}"
  from_port                = var.port
  to_port                  = var.port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.this.id
  source_security_group_id = each.value
}

resource "aws_security_group_rule" "from_cidr" {
  count = length(var.allowed_cidr_blocks) > 0 ? 1 : 0

  type              = "ingress"
  description       = "Postgres from VPN / Client VPN"
  from_port         = var.port
  to_port           = var.port
  protocol          = "tcp"
  security_group_id = aws_security_group.this.id
  cidr_blocks       = var.allowed_cidr_blocks
}
