# ==============================================================================
# API ENABLEMENT
# ==============================================================================
# Enable Organization Policy API in the quota/billing project
# Required before creating any organization policies

resource "google_project_service" "orgpolicy_api" {
  project            = var.project_id
  service            = "orgpolicy.googleapis.com"
  disable_on_destroy = false
}

# ==============================================================================
# ORGANIZATION POLICY: SERVICE ACCOUNT KEY EXPIRY
# ==============================================================================
# Enforces maximum lifespan for user-managed service account keys
# Default: 90 days (2160 hours)
# Addresses GCP security recommendation for mandatory rotation

resource "google_org_policy_policy" "service_account_key_expiry" {
  depends_on = [google_project_service.orgpolicy_api]
  count      = var.enable_key_expiry_policy && !var.dry_run ? 1 : 0
  name       = "organizations/${var.organization_id}/policies/iam.serviceAccountKeyExpiryHours"
  parent     = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      values {
        allowed_values = [tostring(var.key_expiry_hours)]
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
  depends_on = [google_project_service.orgpolicy_api]
  count      = var.enable_key_creation_policy && !var.dry_run ? 1 : 0
  name       = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyCreation"
  parent     = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      enforce = "TRUE"
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
  depends_on = [google_project_service.orgpolicy_api]
  count      = var.enable_key_upload_policy && !var.dry_run ? 1 : 0
  name       = "organizations/${var.organization_id}/policies/iam.disableServiceAccountKeyUpload"
  parent     = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      enforce = "TRUE"
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
  depends_on = [google_project_service.orgpolicy_api]
  count      = var.enable_domain_restriction_policy && length(var.allowed_policy_member_domains) > 0 ? 1 : 0
  name       = "organizations/${var.organization_id}/policies/iam.allowedPolicyMemberDomains"
  parent     = "organizations/${var.organization_id}"

  spec {
    inherit_from_parent = false

    rules {
      values {
        allowed_values = var.allowed_policy_member_domains
      }
    }
  }
}
