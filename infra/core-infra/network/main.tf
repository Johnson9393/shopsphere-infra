module "vpc" {
  source = "git::https://github.com/Johnson9393/aws-vpc-module.git?ref=v1.1.0"

  aws_region = var.aws_region
  vpc_name   = var.vpc_name
  vpc_cidr   = var.vpc_cidr

  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  rds_subnets     = var.rds_subnets

  need_ngw        = var.need_ngw
  need_single_ngw = var.need_single_ngw

  default_tags = {
    Project     = var.project_name
    Account     = var.account
    module_name = "vpc"
  }
}
