project_name = "shopsphere"
environment  = "preprod"
account      = "prod"
aws_region   = "us-east-1"

network_state_bucket = "shopsphere-tfstate-prod-use1"
network_state_key    = "prod/preprod/core-infra/network/terraform.tfstate"

redis_node_type   = "cache.t4g.micro"
extra_client_cidrs = ["10.14.0.0/16"]
