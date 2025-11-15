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
    prefix = "gcp/cost-management/budgets/terraform.tfstate"
  }
}

provider "google" {
  region = var.gcp_region
  
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "budgets"
    purpose     = "cost-management"
  }
}

# Get current project information
data "google_project" "current" {}

locals {
  project_id = data.google_project.current.project_id
}

# Enable Cloud Billing Budget API
resource "google_project_service" "cloudbilling" {
  project = local.project_id
  service = "cloudbilling.googleapis.com"
  
  disable_on_destroy = false
}

# TODO: Add your budget resources here
# Example:
# resource "google_billing_budget" "monthly_budget" {
#   billing_account = var.billing_account_id
#   display_name    = "Monthly Budget"
#   
#   amount {
#     specified_amount {
#       currency_code = "USD"
#       units         = "100"
#     }
#   }
# }