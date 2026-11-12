project_name = "shopsphere"
environment  = "preprod"
account      = "prod"
aws_region   = "us-east-1"

state_bucket  = "shopsphere-tfstate-prod-use1"
eks_state_key = "prod/preprod/core-infra/eks/terraform.tfstate"

git_repo_url = "https://github.com/Johnson9393/shopsphere-gitops.git"

allow_image_replication_from_role_arn = "arn:aws:iam::071138597726:role/dev-shopsphere-image-replication"

domain_name         = "infralabx.space"
dns_assume_role_arn = "arn:aws:iam::023192525105:role/shopsphere-dns"
