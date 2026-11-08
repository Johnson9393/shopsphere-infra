output "dns_role_arn" {
  description = "Pass this to the member-account k8-services stack as dns_assume_role_arn"
  value       = aws_iam_role.dns.arn
}
