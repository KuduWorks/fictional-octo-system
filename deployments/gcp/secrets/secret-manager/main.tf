terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.26"
    }
  }
}

provider "google" {
  project               = var.project_id
  region                = var.gcp_region
  user_project_override = true
  billing_project       = var.project_id

  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "secret-manager"
    purpose     = "secret-management"
  }
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  project = var.project_id
  service = "secretmanager.googleapis.com"

  disable_on_destroy = false
}

# TODO: Add your secret resources here
# Example:
# resource "google_secret_manager_secret" "example" {
#   secret_id = "example-secret"
#   
#   replication {
#     auto {}
#   }
# }