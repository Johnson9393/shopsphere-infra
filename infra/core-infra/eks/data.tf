data "terraform_remote_state" "network" {
  backend = "s3"

  config = {
    bucket = var.network_state_bucket
    key    = var.network_state_key
    region = var.aws_region
  }
}

locals {
  private_subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids_by_environment[var.environment]
}
