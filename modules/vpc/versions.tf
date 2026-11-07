terraform {
  required_version = ">=1.12.0" # It's a major version where an be used more 1.12

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Minor version  can be used within 6xx version only
    }
  }
}
