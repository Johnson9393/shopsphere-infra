project_name = "shopsphere"
account      = "nonprod"
aws_region   = "us-east-1"

environments = ["dev", "qa", "uat"]

vpc_name = "nonprod-shopsphere-vpc"
vpc_cidr = "10.0.0.0/16"

enable_dns_hostnames = true
enable_dns_support   = true

# Shared by dev, qa, and uat. One subnet per Availability Zone.
public_subnets = [
  {
    cidr              = "10.0.0.0/24"
    availability_zone = "us-east-1a"
    prefix            = "public-1a"
  },
  {
    cidr              = "10.0.1.0/24"
    availability_zone = "us-east-1b"
    prefix            = "public-1b"
  }
]

# One pair per environment. The prefix starts with the environment name.
private_subnets = [
  {
    cidr              = "10.0.10.0/24"
    availability_zone = "us-east-1a"
    prefix            = "dev-private-1a"
  },
  {
    cidr              = "10.0.11.0/24"
    availability_zone = "us-east-1b"
    prefix            = "dev-private-1b"
  },
  {
    cidr              = "10.0.20.0/24"
    availability_zone = "us-east-1a"
    prefix            = "qa-private-1a"
  },
  {
    cidr              = "10.0.21.0/24"
    availability_zone = "us-east-1b"
    prefix            = "qa-private-1b"
  },
  {
    cidr              = "10.0.30.0/24"
    availability_zone = "us-east-1a"
    prefix            = "uat-private-1a"
  },
  {
    cidr              = "10.0.31.0/24"
    availability_zone = "us-east-1b"
    prefix            = "uat-private-1b"
  }
]

# Shared by the single non-prod Aurora cluster.
rds_subnets = [
  {
    cidr              = "10.0.100.0/24"
    availability_zone = "us-east-1a"
    prefix            = "rds-1a"
  },
  {
    cidr              = "10.0.101.0/24"
    availability_zone = "us-east-1b"
    prefix            = "rds-1b"
  }
]

need_ngw        = true
need_single_ngw = false
