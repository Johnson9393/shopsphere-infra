project_name = "shopsphere"
environment  = "prod"
account      = "prod"
aws_region   = "us-west-1"
state_region = "us-east-1"

network_state_bucket = "shopsphere-tfstate-prod-use1"
network_state_key    = "prod/prod/dr/core-infra/network/terraform.tfstate"

redis_node_type = "cache.r6g.large"
msk_instance_type = "kafka.m5.large"
msk_volume_size   = 100

primary_state_bucket = "shopsphere-tfstate-prod-use1"
primary_state_key    = "prod/prod/app-infra/data-services/terraform.tfstate"
extra_client_cidrs   = ["10.5.0.0/16"]
