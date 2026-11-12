project_name = "shopsphere"
environment  = "dev"
account      = "nonprod"
aws_region   = "us-east-1"

state_bucket  = "shopsphere-tfstate-nonprod-use1"
eks_state_key = "nonprod/dev/core-infra/eks/terraform.tfstate"

git_repo_url = "https://github.com/Johnson9393/shopsphere-gitops.git"

replicate_images_to = [
  {
    bucket     = "arn:aws:s3:::preprod-shopsphere-images-991232066823"
    account_id = "991232066823"
  },
  {
    bucket     = "arn:aws:s3:::prod-shopsphere-images-991232066823"
    account_id = "991232066823"
  },
]

domain_name         = "infralabx.space"
dns_assume_role_arn = "arn:aws:iam::023192525105:role/shopsphere-dns"
