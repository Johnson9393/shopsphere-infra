project_name = "shopsphere"
account      = "prod"
aws_region   = "us-west-1"

environments = ["preprod"]

vpc_name = "preprod-shopsphere-dr-vpc"
vpc_cidr = "10.14.0.0/16"

enable_dns_hostnames = true
enable_dns_support   = true

public_subnets = [
  {
    cidr              = "10.14.0.0/24"
    availability_zone = "us-west-1a"
    prefix            = "public-1a"
  },
  {
    cidr              = "10.14.0.1/24"
    availability_zone = "us-west-1b"
    prefix            = "public-1b"
  }
]

private_subnets = [
  {
    cidr              = "10.14.1.0/24"
    availability_zone = "us-west-1a"
    prefix            = "preprod-private-1a"
  },
  {
    cidr              = "10.14.1.1/24"
    availability_zone = "us-west-1b"
    prefix            = "preprod-private-1b"
  }
]

rds_subnets = [
  {
    cidr              = "10.14.100.0/24"
    availability_zone = "us-west-1a"
    prefix            = "rds-1a"
  },
  {
    cidr              = "10.14.101.0/24"
    availability_zone = "us-west-1b"
    prefix            = "rds-1b"
  }
]

need_ngw        = true
need_single_ngw = false
