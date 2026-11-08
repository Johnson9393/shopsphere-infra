variable "project_name" {
  description = "Project name"
  type        = string
  default     = "shopsphere"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "domain_name" {
  description = "Public hosted zone that already exists in this management account"
  type        = string
  default     = "infralabx.space"
}

variable "member_account_ids" {
  description = "Account roots allowed to assume the DNS role. Non-prod is the first."
  type        = list(string)
  default     = ["arn:aws:iam::071138597726:root"]
}
