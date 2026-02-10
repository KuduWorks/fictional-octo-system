output "organization_id" {
  description = "GCP Organization ID where policies are applied"
  value       = var.organization_id
}

output "dry_run_mode" {
  description = "Current dry-run mode status"
  value       = var.dry_run
}

output "policies_deployed" {
  description = "List of deployed organization policies"
  value = {
    key_expiry_policy         = var.enable_key_expiry_policy
    key_creation_policy       = var.enable_key_creation_policy
    key_upload_policy         = var.enable_key_upload_policy
    domain_restriction_policy = var.enable_domain_restriction_policy && length(var.allowed_policy_member_domains) > 0
  }
}

output "policy_configuration" {
  description = "Organization policy configuration summary"
  value = {
    key_expiry_hours              = var.key_expiry_hours
    allowed_policy_member_domains = var.allowed_policy_member_domains
    excluded_folders_count        = length(var.exclude_folders)
    excluded_projects_count       = length(var.exclude_projects)
  }
}

output "exempted_resources" {
  description = "Resources exempted from organization policies"
  value = {
    folders  = var.exclude_folders
    projects = var.exclude_projects
  }
  sensitive = false
}

output "dry_run_warning" {
  description = "Warning message if policies are in dry-run mode"
  value       = var.dry_run ? "⚠️  DRY-RUN MODE: Policies are NOT created. Set dry_run=false in terraform.tfvars to enforce." : "✓ ENFORCED MODE: Policy violations will be blocked."
}

output "exemption_review_reminder" {
  description = "Reminder to review exemptions periodically"
  value       = length(var.exclude_folders) > 0 || length(var.exclude_projects) > 0 ? "📋 ${length(var.exclude_folders)} folder(s) and ${length(var.exclude_projects)} project(s) exempt. Review exemptions quarterly." : "No exemptions configured."
}

output "policies_summary" {
  description = "Human-readable summary of deployed policies"
  value       = <<-EOT
  
  ════════════════════════════════════════════════════════════════
  GCP ORGANIZATION POLICIES DEPLOYED
  ════════════════════════════════════════════════════════════════
  
  Organization ID: ${var.organization_id}
  Mode: ${var.dry_run ? "DRY-RUN (testing)" : "ENFORCED (production)"}
  
  Policies Active:
  ${var.enable_key_expiry_policy ? "  ✓ Service Account Key Expiry (${var.key_expiry_hours} hours / ${var.key_expiry_hours / 24} days)" : "  ✗ Service Account Key Expiry (disabled)"}
  ${var.enable_key_creation_policy ? "  ✓ Disable Service Account Key Creation" : "  ✗ Disable Service Account Key Creation (disabled)"}
  ${var.enable_key_upload_policy ? "  ✓ Disable Service Account Key Upload" : "  ✗ Disable Service Account Key Upload (disabled)"}
  ${var.enable_domain_restriction_policy && length(var.allowed_policy_member_domains) > 0 ? "  ✓ Allowed Policy Member Domains (${length(var.allowed_policy_member_domains)} domain(s))" : "  ✗ Allowed Policy Member Domains (disabled or no domains configured)"}
  
  Exemptions:
    Folders: ${length(var.exclude_folders)} exempted
    Projects: ${length(var.exclude_projects)} exempted
  
  ════════════════════════════════════════════════════════════════
  NEXT STEPS
  ════════════════════════════════════════════════════════════════
  ${var.dry_run ? "Dry-run mode: Policies are NOT enforced.\n  1. Review policy configuration above\n  2. Set dry_run = false in terraform.tfvars\n  3. Run terraform apply to enforce policies" : "1. Monitor compliance via Cloud Logging\n  2. Review exemptions quarterly\n  3. Deploy service account key audit automation"}
  
  ════════════════════════════════════════════════════════════════
  EOT
}
