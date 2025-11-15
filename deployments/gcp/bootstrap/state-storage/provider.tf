provider "google" {
  project = var.project_id
  region  = var.gcp_region
  
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "state-storage-bootstrap"
    purpose     = "terraform-state"
  }
}