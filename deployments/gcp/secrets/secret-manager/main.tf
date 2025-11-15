terraform {
  required_version = ">= 1.0"
  
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  
  # GCS backend configuration - update PROJECT-ID with your actual project
  backend "gcs" {
    bucket = "fictional-octo-system-tfstate-PROJECT-ID"
    prefix = "gcp/secrets/secret-manager/terraform.tfstate"
  }
}

provider "google" {
  region = var.gcp_region
  
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "secret-manager"
    purpose     = "secret-management"
  }
}

# Get current project information
data "google_project" "current" {}

locals {
  project_id = data.google_project.current.project_id
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  project = local.project_id
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