project_name = "shopsphere"
account      = "prod"
aws_region   = "us-west-1"

environments = ["prod"]

vpc_name = "prod-shopsphere-dr-vpc"
vpc_cidr = "10.15.0.0/16"

enable_dns_hostnames = true
enable_dns_support   = true

public_subnets = [
  {
    cidr              = "10.15.0.0/24"
    availability_zone = "us-west-1a"
    prefix            = "public-1a"
  },
  {
    cidr              = "10.15.2.0/24"
    availability_zone = "us-west-1b"
    prefix            = "public-1b"
  }
]

private_subnets = [
  {
    cidr              = "10.15.1.0/24"
    availability_zone = "us-west-1a"
    prefix            = "prod-private-1a"
  },
  {
    cidr              = "10.15.3.0/24"
    availability_zone = "us-west-1b"
    prefix            = "prod-private-1b"
  }
]

rds_subnets = [
  {
    cidr              = "10.15.100.0/24"
    availability_zone = "us-west-1a"
    prefix            = "rds-1a"
  },
  {
    cidr              = "10.15.101.0/24"
    availability_zone = "us-west-1b"
    prefix            = "rds-1b"
  }
]

need_ngw        = true
need_single_ngw = false

peer_state_bucket = "shopsphere-tfstate-prod-use1"
peer_state_key    = "prod/prod/core-infra/network/terraform.tfstate"
peer_region       = "us-east-1"
