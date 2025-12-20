output "required_tag_keys" {
  description = "List of required tag keys that must be present on all resources"
  value       = local.required_tag_keys
}

output "governance_tags" {
  description = "Governance-required tags (environment, team, costcenter)"
  value       = local.governance_tags
}

output "baseline_tags" {
  description = "Complete baseline tags (governance + common tags)"
  value       = local.baseline_tags
}

output "merge_helper" {
  description = "Helper function for merging tags in your resources. Use: merge(module.required_tags.baseline_tags, { your_custom_tags })"
  value       = "merge(module.required_tags.baseline_tags, { custom_tag_key = \"custom_value\" })"
}
