project_name = "shopsphere"
account      = "prod"
aws_region   = "us-east-1"

environments = ["prod"]

vpc_name = "prod-shopsphere-vpc"
vpc_cidr = "10.5.0.0/16"

enable_dns_hostnames = true
enable_dns_support   = true

public_subnets = [
  {
    cidr              = "10.5.0.0/24"
    availability_zone = "us-east-1a"
    prefix            = "public-1a"
  },
  {
    cidr              = "10.5.0.1/24"
    availability_zone = "us-east-1b"
    prefix            = "public-1b"
  }
]

private_subnets = [
  {
    cidr              = "10.5.1.0/24"
    availability_zone = "us-east-1a"
    prefix            = "prod-private-1a"
  },
  {
    cidr              = "10.5.1.1/24"
    availability_zone = "us-east-1b"
    prefix            = "prod-private-1b"
  }
]

rds_subnets = [
  {
    cidr              = "10.5.100.0/24"
    availability_zone = "us-east-1a"
    prefix            = "rds-1a"
  },
  {
    cidr              = "10.5.101.0/24"
    availability_zone = "us-east-1b"
    prefix            = "rds-1b"
  }
]

need_ngw        = true
need_single_ngw = false
