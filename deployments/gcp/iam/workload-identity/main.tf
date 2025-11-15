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
}

# Get current project information
data "google_project" "current" {
  project_id = var.project_id
}

locals {
  project_id = var.project_id
  project_number = data.google_project.current.number
}

# Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_actions" {
  provider                  = google-beta
  project                   = local.project_id
  workload_identity_pool_id = var.workload_identity_pool_name
  display_name              = "GitHub Actions Pool"
  description               = "Workload Identity Pool for GitHub Actions"
  disabled                  = false
}

# Service accounts for each GitHub repository
resource "google_service_account" "github_repos" {
  for_each = var.github_repositories
  
  account_id   = "${each.key}-github-actions"
  display_name = "GitHub Actions SA for ${each.key}"
  description  = "Service account for GitHub Actions in ${each.key} repository"
  project      = local.project_id
}

# Workload Identity Providers for each repository
resource "google_iam_workload_identity_pool_provider" "github_repos" {
  for_each = var.github_repositories
  
  provider                           = google-beta
  project                            = local.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_actions.workload_identity_pool_id
  workload_identity_pool_provider_id = "${each.key}-github-provider"
  
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }
  attribute_condition = "attribute.repository==\"KuduWorks/fictional-octo-system\""
  
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# Allow GitHub Actions to impersonate service accounts
resource "google_service_account_iam_member" "workload_identity" {
  for_each = var.github_repositories
  
  service_account_id = google_service_account.github_repos[each.key].name
  role              = "roles/iam.workloadIdentityUser"
  member            = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_actions.name}/attribute.repository/${each.value.org}/${each.value.repo}"
}

# Grant IAM roles to service accounts based on configuration
resource "google_project_iam_member" "github_repo_roles" {
  for_each = {
    for combo in flatten([
      for repo_key, repo_config in var.github_repositories : [
        for role in repo_config.roles : {
          key  = "${repo_key}-${role}"
          repo = repo_key
          role = role
        }
      ]
    ]) : combo.key => combo
  }
  
  project = local.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.github_repos[each.value.repo].email}"
}

# Grant storage access for Terraform state (if enabled)
resource "google_storage_bucket_iam_member" "terraform_state_access" {
  for_each = var.enable_terraform_state_access ? var.github_repositories : {}
  
  bucket = var.terraform_state_bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.github_repos[each.key].email}"
}

# Create custom IAM roles if specified
resource "google_project_iam_custom_role" "custom_roles" {
  for_each = var.custom_roles
  
  project     = local.project_id
  role_id     = each.key
  title       = each.value.title
  description = each.value.description
  permissions = each.value.permissions
  stage       = each.value.stage
}

# Assign custom roles to service accounts
resource "google_project_iam_member" "custom_role_assignments" {
  for_each = {
    for combo in flatten([
      for repo_key, repo_config in var.github_repositories : [
        for custom_role in repo_config.custom_roles : {
          key         = "${repo_key}-${custom_role}"
          repo        = repo_key
          custom_role = custom_role
        }
      ]
    ]) : combo.key => combo
  }
  
  project = local.project_id
  role    = "projects/${local.project_id}/roles/${each.value.custom_role}"
  member  = "serviceAccount:${google_service_account.github_repos[each.value.repo].email}"
  
  depends_on = [google_project_iam_custom_role.custom_roles]
}


# Create service account keys for GitHub Actions
resource "google_service_account_key" "github_keys" {
  for_each           = var.github_repositories
  service_account_id = google_service_account.github_repos[each.key].name
  key_algorithm      = "KEY_ALG_RSA_2048"
}

# Store service account keys in Secret Manager
resource "google_secret_manager_secret" "github_sa_keys" {
  for_each  = var.github_repositories
  secret_id = "github-sa-key-${each.key}"
  
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "github_sa_key_versions" {
  for_each    = var.github_repositories
  secret      = google_secret_manager_secret.github_sa_keys[each.key].id
  secret_data = base64decode(google_service_account_key.github_keys[each.key].private_key)
}
