project_name = "shopsphere"
environment  = "uat"
account      = "nonprod"
aws_region   = "us-east-1"

state_bucket  = "shopsphere-tfstate-nonprod-use1"
eks_state_key = "nonprod/uat/core-infra/eks/terraform.tfstate"

git_repo_url = "https://github.com/Johnson9393/shopsphere-gitops.git"

domain_name         = "infralabx.space"
dns_assume_role_arn = "arn:aws:iam::023192525105:role/shopsphere-dns"
