project_name = "shopsphere"
account      = "prod"
aws_region   = "us-west-1"
state_region = "us-east-1"

environments = ["prod"]

network_state_bucket = "shopsphere-tfstate-prod-use1"
network_state_key    = "prod/prod/dr/core-infra/network/terraform.tfstate"
primary_state_key    = "prod/prod/app-infra/aurora/terraform.tfstate"

cluster_identifier = "prod-shopsphere-dr"
engine_version     = "15.10"
database_name      = "postgres"
master_username    = "shopsphere_admin"

instances = {
  writer = {
    instance_class = "db.r6g.large"
    promotion_tier = 0
  }
  reader = {
    instance_class = "db.r6g.large"
    promotion_tier = 1
  }
}

create_global_cluster   = false
is_global_secondary     = true
backup_retention_period = 14
skip_final_snapshot     = false
deletion_protection     = true
