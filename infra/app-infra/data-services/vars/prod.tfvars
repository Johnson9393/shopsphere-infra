project_name = "shopsphere"
environment  = "prod"
account      = "prod"
aws_region   = "us-east-1"

network_state_bucket = "shopsphere-tfstate-prod-use1"
network_state_key    = "prod/prod/core-infra/network/terraform.tfstate"

redis_node_type    = "cache.r6g.large"
mq_instance_type   = "mq.m5.large"
mq_deployment_mode = "CLUSTER_MULTI_AZ"
