terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
  
  # Store this module's state locally initially, then migrate to GCS
  # ⚠️ IMPORTANT: Backend configuration does not support variables.
  # You MUST manually update the bucket name below with your GCP project ID
  # before migrating state to GCS.
  #
  # Steps:
  # 1. First run: Comment out this entire backend block and run `terraform init`
  #    and `terraform apply` to create the GCS bucket (state stored locally).
  # 2. After bucket creation: Update the bucket name below to match your
  #    actual bucket name (which includes your GCP project ID).
  # 3. Copy backend.tf.example to backend.tf, update project ID
  # 4. Run `terraform init -migrate-state` to move local state to GCS.
  #
  # Example bucket name format: fictional-octo-system-tfstate-<YOUR-PROJECT-ID>
  # backend "gcs" {
  #   bucket = "fictional-octo-system-tfstate-PROJECT-ID"
  #   prefix = "bootstrap/terraform.tfstate"
  # }
}

provider "google-beta" {
  region = var.gcp_region
}

# Get current project information
data "google_project" "current" {}
data "google_client_config" "current" {}

locals {
  project_id  = data.google_project.current.project_id
  bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "fictional-octo-system-tfstate-${local.project_id}"
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "storage.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com"
  ])
  
  project = local.project_id
  service = each.value
  
  disable_on_destroy = false
}

# GCS Bucket for Terraform State
resource "google_storage_bucket" "terraform_state" {
  name     = local.bucket_name
  location = var.gcs_location
  
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = true
  }
  
  # Enable versioning for state recovery
  versioning {
    enabled = true
  }
  
  # Enable encryption (only if KMS key is specified)
  dynamic "encryption" {
    for_each = var.kms_key_name != "" ? [var.kms_key_name] : []
    content {
      default_kms_key_name = var.kms_key_name
    }
  }
  
  # Block public access
  public_access_prevention = "enforced"
  
  # Uniform bucket-level access
  uniform_bucket_level_access = true
  
  # Lifecycle management for old versions
  lifecycle_rule {
    condition {
      num_newer_versions = var.state_version_retention_count
    }
    action {
      type = "Delete"
    }
  }
  
  # Delete old versions after retention period
  lifecycle_rule {
    condition {
      age = var.state_version_retention_days
    }
    action {
      type = "Delete"
    }
  }
  
  labels = {
    name        = "terraform-state-storage"
    purpose     = "terraform-state"
    managed_by  = "terraform"
    environment = var.environment
  }
  
  depends_on = [google_project_service.required_apis]
}

# Service Account for GitHub Actions CI/CD
resource "google_service_account" "github_actions" {
  account_id   = var.github_actions_sa_name
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions CI/CD workflows"
  project      = local.project_id
  
  depends_on = [google_project_service.required_apis]
}

# Grant minimal permissions to service account for state bucket access
resource "google_storage_bucket_iam_member" "terraform_state_access" {
  bucket = google_storage_bucket.terraform_state.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_actions.email}"
}

# Grant service account token creator role for Workload Identity Federation
resource "google_service_account_iam_member" "github_actions_token_creator" {
  service_account_id = google_service_account.github_actions.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.github_actions.email}"
}

# Workload Identity Pool (organization-wide for consistency)
resource "google_iam_workload_identity_pool" "github_actions" {
  provider                  = google-beta
  project                   = local.project_id
  workload_identity_pool_id = var.workload_identity_pool_name
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Federation pool for GitHub Actions across organization"
  disabled                  = false
  
  depends_on = [google_project_service.required_apis]
}

# Workload Identity Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github" {
  provider                           = google-beta
  project                            = local.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "github"
  display_name                       = "GitHub OIDC Provider"
  description                        = "GitHub Actions OIDC provider for repository access"
  disabled                          = false
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
  
  attribute_condition = "assertion.repository=='${var.github_org}/${var.github_repo}'"
}

# Allow GitHub Actions to impersonate the service account
resource "google_service_account_iam_member" "github_actions_workload_identity" {
  service_account_id = google_service_account.github_actions.name
  role              = "roles/iam.workloadIdentityUser"
  member            = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${var.github_org}/${var.github_repo}"
}

# Optional: Grant additional IAM roles for deployment (if enabled)
resource "google_project_iam_member" "github_actions_additional_roles" {
  for_each = var.enable_deployment_roles ? toset(var.deployment_roles) : toset([])
  
  project = local.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions.email}"
}

# # Optional: Enable audit logging for state bucket (if enabled)
# resource "google_storage_bucket_iam_audit_config" "terraform_state_audit" {
#   count  = var.enable_audit_logging ? 1 : 0
#   bucket = google_storage_bucket.terraform_state.name
  
#   audit_log_config {
#     log_type         = "ADMIN_READ"
#     exempted_members = []
#   }
  
#   audit_log_config {
#     log_type         = "DATA_READ"
#     exempted_members = []
#   }
  
#   audit_log_config {
#     log_type         = "DATA_WRITE"
#     exempted_members = []
#   }
# }

resource "google_project_iam_audit_config" "storage_audit" {
  count   = var.enable_audit_logging ? 1 : 0
  project = local.project_id
  service = "storage.googleapis.com"
  
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  
  audit_log_config {
    log_type = "DATA_READ"
  }
  
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}