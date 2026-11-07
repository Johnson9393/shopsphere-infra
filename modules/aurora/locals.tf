locals {
  cluster_identifier = coalesce(var.cluster_identifier, "${var.env}-shopsphere")

  # Secondary has no master user. Credentials live on the primary only.
  is_primary = !var.is_global_secondary

  tags = merge(var.default_tags, {
    Environment = var.env
    Application = "shopsphere"
    ManagedBy   = "Terraform"
  })
}
