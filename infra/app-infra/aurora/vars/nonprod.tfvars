project_name = "shopsphere"
account      = "nonprod"
aws_region   = "us-east-1"

environments = ["dev", "qa", "uat"]

network_state_bucket = "shopsphere-tfstate-nonprod-use1"
network_state_key    = "nonprod/core-infra/network/terraform.tfstate"

cluster_identifier = "nonprod-shopsphere"
engine_version     = "15.10"
database_name      = "postgres"
master_username    = "shopsphere_admin"

instances = {
  writer = {
    instance_class = "db.t3.medium"
    promotion_tier = 0
  }
  reader = {
    instance_class = "db.t3.medium"
    promotion_tier = 1
  }
}

create_global_cluster   = false
backup_retention_period = 7
skip_final_snapshot     = true
deletion_protection     = false
