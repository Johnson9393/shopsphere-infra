provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Account     = var.account
      ManagedBy   = "Terraform"
      Stack       = "core-infra-k8-services"
    }
  }
}

provider "aws" {
  alias  = "west"
  region = "us-west-1"

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Account     = var.account
      ManagedBy   = "Terraform"
      Stack       = "core-infra-k8-services"
    }
  }
}

provider "aws" {
  alias  = "dns"
  region = var.aws_region

  assume_role {
    role_arn = var.dns_assume_role_arn
  }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      Account     = var.account
      ManagedBy   = "Terraform"
      Stack       = "core-infra-k8-services"
    }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes = {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
