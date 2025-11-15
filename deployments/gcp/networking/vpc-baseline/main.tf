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
    prefix = "gcp/networking/vpc-baseline/terraform.tfstate"
  }
}

provider "google" {
  region = var.gcp_region
  
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "vpc-baseline"
    purpose     = "networking"
  }
}

# Get current project information
data "google_project" "current" {}

locals {
  project_id = data.google_project.current.project_id
}

# Enable Compute Engine API (required for VPC)
resource "google_project_service" "compute" {
  project = local.project_id
  service = "compute.googleapis.com"
  
  disable_on_destroy = false
}

# TODO: Add your VPC resources here
# Example:
# resource "google_compute_network" "vpc" {
#   name                    = "main-vpc"
#   auto_create_subnetworks = false
# }
# 
# resource "google_compute_subnetwork" "subnet" {
#   name          = "main-subnet"
#   ip_cidr_range = "10.0.0.0/16"
#   region        = var.gcp_region
#   network       = google_compute_network.vpc.id
# }