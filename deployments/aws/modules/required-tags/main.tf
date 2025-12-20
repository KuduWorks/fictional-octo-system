# AWS Required Tags Module
# Provides governance-enforced tag baseline for all AWS resources
# Developers use this module to get required tags and merge with custom tags

terraform {
  required_version = ">= 1.0"
}

# Local values for required tags
# These are enforced by AWS Config and must be present on all resources
locals {
  # Required tag keys (must be present)
  required_tag_keys = [
    "environment",
    "team",
    "costcenter"
  ]

  # Base governance tags
  # These provide the minimum required tags for compliance
  governance_tags = {
    environment = var.environment
    team        = var.team
    costcenter  = var.costcenter
  }

  # Optional common tags that can be included
  common_tags = {
    managed_by = "terraform"
    repository = var.repository_name
  }

  # Combined baseline (governance + common)
  baseline_tags = merge(
    local.governance_tags,
    var.include_common_tags ? local.common_tags : {}
  )
}
