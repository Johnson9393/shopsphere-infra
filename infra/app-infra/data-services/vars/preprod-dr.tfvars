project_name = "shopsphere"
environment  = "preprod"
account      = "prod"
aws_region   = "us-west-1"
state_region = "us-east-1"

network_state_bucket = "shopsphere-tfstate-prod-use1"
network_state_key    = "prod/preprod/dr/core-infra/network/terraform.tfstate"

redis_node_type = "cache.t4g.micro"

primary_state_bucket = "shopsphere-tfstate-prod-use1"
primary_state_key    = "prod/preprod/app-infra/data-services/terraform.tfstate"
extra_client_cidrs   = ["10.4.0.0/16"]
