provider "google" {
  project = var.project_id
  region  = var.gcp_region
  
  default_labels = {
    environment = var.environment
    managed_by  = "terraform"
    module      = "workload-identity"
    purpose     = "github-actions-auth"
  }
}

provider "google-beta" {
  project = var.project_id
  region  = var.gcp_region
}