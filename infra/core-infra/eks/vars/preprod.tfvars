project_name = "shopsphere"
environment  = "preprod"
account      = "prod"
aws_region   = "us-east-1"

network_state_bucket = "shopsphere-tfstate-prod-use1"
network_state_key    = "prod/preprod/core-infra/network/terraform.tfstate"

cluster_name    = "preprod-shopsphere"
cluster_version = "1.35"

endpoint_private_access = true
endpoint_public_access  = true
public_access_cidrs     = ["0.0.0.0/0"]

eks_nodes = {
  application = {
    instance_type      = "t3.medium"
    desired_size       = 2
    min_size           = 2
    max_size           = 4
    kubernetes_version = "1.35"
  }
}

ami_type = "AL2023_x86_64_STANDARD"
