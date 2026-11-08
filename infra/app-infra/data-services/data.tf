data "aws_caller_identity" "current" {}

data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.network_state_bucket
    key    = var.network_state_key
    region = var.aws_region
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.terraform_remote_state.network.outputs.private_subnet_ids_by_environment[var.environment])
  id       = each.value
}

locals {
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids_by_environment[var.environment]
  private_cidrs      = [for subnet in data.aws_subnet.private : subnet.cidr_block]
  mq_subnet_ids      = var.mq_deployment_mode == "SINGLE_INSTANCE" ? [local.private_subnet_ids[0]] : local.private_subnet_ids
}
