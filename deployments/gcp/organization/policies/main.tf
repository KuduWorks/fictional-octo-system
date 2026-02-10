# ==============================================================================
# ORGANIZATION POLICY: SERVICE ACCOUNT KEY EXPIRY
# ==============================================================================
# Enforces maximum lifespan for user-managed service account keys
# Default: 90 days (2160 hours)
# Addresses GCP security recommendation for mandatory rotation

resource "google_org_policy_policy" "service_account_key_expiry" {
  count  = var.enable_key_expiry_policy ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.serviceAccountKeyExpiryHours"
  parent = "organizations/${var.organization_id}"

  spec {
    # Dry-run mode: Log violations without enforcement
    # Set dry_run = false in terraform.tfvars to enforce
    inherit_from_parent = false

    rules {
      condition {
        expression = var.dry_run ? "false" : "true"
      }
      values {
        allowed_values = [tostring(var.key_expiry_hours)]
      }
    }

    # Apply to all resources except exempted folders/projects
    dynamic "rules" {
      for_each = length(var.exclude_folders) > 0 || length(var.exclude_projects) > 0 ? [1] : []
      content {
        condition {
          expression = join(" || ", concat(
            [for f in var.exclude_folders : "resource.matchTag('${f}', 'folder')"],
            [for p in var.exclude_projects : "resource.matchTag('${p}', 'project')"]
          ))
        }
        allow_all = true
      }
    }
  }
}

# ==============================================================================
# ORGANIZATION POLICY: DISABLE SERVICE ACCOUNT KEY CREATION
# ==============================================================================
# Prevents creation of new user-managed service account keys
# Enforces use of Workload Identity Federation for automation
# Addresses GCP security recommendation for keyless authentication

resource "google_org_policy_policy" "disable_key_creation" {
  count  = var.enable_key_creation_policy ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      condition {
        expression = var.dry_run ? "false" : "true"
      }
      enforce = "TRUE"
    }

    # Exemptions for folders/projects requiring manual key management
    dynamic "rules" {
      for_each = length(var.exclude_folders) > 0 || length(var.exclude_projects) > 0 ? [1] : []
      content {
        condition {
          expression = join(" || ", concat(
            [for f in var.exclude_folders : "resource.matchTag('${f}', 'folder')"],
            [for p in var.exclude_projects : "resource.matchTag('${p}', 'project')"]
          ))
        }
        enforce = "FALSE"
      }
    }
  }
}

# ==============================================================================
# ORGANIZATION POLICY: DISABLE SERVICE ACCOUNT KEY UPLOAD
# ==============================================================================
# Prevents uploading external service account keys
# Blocks importing keys generated outside GCP
# Reduces risk of compromised external keys

resource "google_org_policy_policy" "disable_key_upload" {
  count  = var.enable_key_upload_policy ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyUpload"
  parent = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      condition {
        expression = var.dry_run ? "false" : "true"
      }
      enforce = "TRUE"
    }

    # Exemptions for specific use cases (e.g., legacy integrations)
    dynamic "rules" {
      for_each = length(var.exclude_folders) > 0 || length(var.exclude_projects) > 0 ? [1] : []
      content {
        condition {
          expression = join(" || ", concat(
            [for f in var.exclude_folders : "resource.matchTag('${f}', 'folder')"],
            [for p in var.exclude_projects : "resource.matchTag('${p}', 'project')"]
          ))
        }
        enforce = "FALSE"
      }
    }
  }
}

# ==============================================================================
# ORGANIZATION POLICY: ALLOWED POLICY MEMBER DOMAINS
# ==============================================================================
# Restricts IAM policy members to specific domains
# Prevents external users from being granted access
# Enforces organizational boundary for access control

resource "google_org_policy_policy" "allowed_policy_member_domains" {
  count  = var.enable_domain_restriction_policy && length(var.allowed_policy_member_domains) > 0 ? 1 : 0
  name   = "organizations/${var.organization_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      condition {
        expression = var.dry_run ? "false" : "true"
      }
      values {
        allowed_values = var.allowed_policy_member_domains
      }
    }

    # Exemptions for cross-organization collaboration
    dynamic "rules" {
      for_each = length(var.exclude_folders) > 0 || length(var.exclude_projects) > 0 ? [1] : []
      content {
        condition {
          expression = join(" || ", concat(
            [for f in var.exclude_folders : "resource.matchTag('${f}', 'folder')"],
            [for p in var.exclude_projects : "resource.matchTag('${p}', 'project')"]
          ))
        }
        allow_all = true
      }
    }
  }
}
