output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.current.id
}

output "organization_root_id" {
  description = "AWS Organization root ID where SCP is attached"
  value       = data.aws_organizations_organization.current.roots[0].id
}

output "region_restriction_policy_id" {
  description = "ID of the region restriction SCP"
  value       = aws_organizations_policy.region_restriction.id
}

output "region_restriction_policy_arn" {
  description = "ARN of the region restriction SCP"
  value       = aws_organizations_policy.region_restriction.arn
}

output "allowed_regions" {
  description = "List of allowed AWS regions"
  value       = var.allowed_regions
}
