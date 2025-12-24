output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.current.id
}

output "organization_root_id" {
  description = "AWS Organization root ID where SCP is attached"
  value       = data.aws_organizations_organization.current.roots[0].id
}

output "organization_protection_policy_id" {
  description = "ID of the organization protection SCP"
  value       = aws_organizations_policy.organization_protection.id
}

output "organization_protection_policy_arn" {
  description = "ARN of the organization protection SCP"
  value       = aws_organizations_policy.organization_protection.arn
}

output "management_account_id" {
  description = "Management account ID exempted from restrictions"
  value       = var.management_account_id
}
