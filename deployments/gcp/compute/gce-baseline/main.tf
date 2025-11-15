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
    prefix = "gcp/compute/gce-baseline/terraform.tfstate"
  }
}

provider "google" {
  region = var.gcp_region
  
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "gce-baseline"
    purpose     = "compute"
  }
}

# Get current project information
data "google_project" "current" {}

locals {
  project_id = data.google_project.current.project_id
}

# Enable Compute Engine API
resource "google_project_service" "compute" {
  project = local.project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

# TODO: Add your compute instances here
# Example:
# resource "google_compute_instance" "example" {
#   name         = "example-instance"
#   machine_type = "e2-micro"
#   zone         = "${var.gcp_region}-a"
# 
#   boot_disk {
#     initialize_params {
#       image = "ubuntu-os-cloud/ubuntu-2204-lts"
#     }
#   }
# }