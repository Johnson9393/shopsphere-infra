variable "peer_state_bucket" {
  description = "State bucket of the primary-region VPC. Set on a DR network stack so the two VPCs can carry MSK replication."
  type        = string
  default     = ""
}

variable "peer_state_key" {
  description = "State key of the primary-region VPC."
  type        = string
  default     = ""
}

variable "peer_region" {
  description = "Region of the primary VPC."
  type        = string
  default     = "us-east-1"
}

provider "aws" {
  alias  = "primary"
  region = var.peer_region

  default_tags {
    tags = {
      Project   = var.project_name
      Account   = var.account
      ManagedBy = "Terraform"
      Stack     = "core-infra-network"
    }
  }
}

data "terraform_remote_state" "primary_network" {
  count   = var.peer_state_key == "" ? 0 : 1
  backend = "s3"

  config = {
    bucket = var.peer_state_bucket
    key    = var.peer_state_key
    region = "us-east-1"
  }
}

resource "aws_vpc_peering_connection" "primary" {
  count = var.peer_state_key == "" ? 0 : 1

  vpc_id      = module.vpc.vpc_id
  peer_vpc_id = data.terraform_remote_state.primary_network[0].outputs.vpc_id
  peer_region = var.peer_region
  auto_accept = false

  tags = {
    Name = "${var.vpc_name}-to-primary"
  }
}

resource "aws_vpc_peering_connection_accepter" "primary" {
  count    = var.peer_state_key == "" ? 0 : 1
  provider = aws.primary

  vpc_peering_connection_id = aws_vpc_peering_connection.primary[0].id
  auto_accept               = true
}

data "aws_route_tables" "local" {
  count  = var.peer_state_key == "" ? 0 : 1
  vpc_id = module.vpc.vpc_id
}

data "aws_route_tables" "primary" {
  count    = var.peer_state_key == "" ? 0 : 1
  provider = aws.primary
  vpc_id   = data.terraform_remote_state.primary_network[0].outputs.vpc_id
}

resource "aws_route" "local_to_primary" {
  for_each = var.peer_state_key == "" ? toset([]) : data.aws_route_tables.local[0].ids

  route_table_id            = each.value
  destination_cidr_block    = data.terraform_remote_state.primary_network[0].outputs.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary[0].id
}

resource "aws_route" "primary_to_local" {
  for_each = var.peer_state_key == "" ? toset([]) : data.aws_route_tables.primary[0].ids
  provider = aws.primary

  route_table_id            = each.value
  destination_cidr_block    = var.vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.primary[0].id
}
