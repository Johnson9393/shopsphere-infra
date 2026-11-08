project_name = "shopsphere"
environment  = "dev"
account      = "nonprod"
aws_region   = "us-east-1"

network_state_bucket = "shopsphere-tfstate-nonprod-use1"
network_state_key    = "nonprod/core-infra/network/terraform.tfstate"

redis_node_type    = "cache.t4g.micro"
mq_instance_type   = "mq.m5.large"
mq_deployment_mode = "CLUSTER_MULTI_AZ"
