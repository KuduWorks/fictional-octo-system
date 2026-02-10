terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
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
    module      = "essential-contacts"
    purpose     = "security-notifications"
  }
}
