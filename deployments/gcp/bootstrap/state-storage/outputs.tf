output "state_bucket_name" {
  description = "Name of the GCS bucket for Terraform state"
  value       = google_storage_bucket.terraform_state.name
}

output "state_bucket_url" {
  description = "URL of the GCS bucket"
  value       = google_storage_bucket.terraform_state.url
}

output "project_id" {
  description = "GCP Project ID"
  value       = local.project_id
}

output "service_account_email" {
  description = "Email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
}

output "service_account_id" {
  description = "ID of the GitHub Actions service account"
  value       = google_service_account.github_actions.id
}

output "workload_identity_provider" {
  description = "Workload Identity Federation provider ID"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "workload_identity_pool" {
  description = "Workload Identity Federation pool ID"
  value       = google_iam_workload_identity_pool.github_actions.name
}

output "backend_config" {
  description = "Backend configuration to use in other modules"
  value = <<-EOT
    
    Add this to your Terraform modules:
    
    terraform {
      backend "gcs" {
        bucket = "${google_storage_bucket.terraform_state.name}"
        prefix = "gcp/service/module/terraform.tfstate"
      }
    }
    
    Note: Replace 'service/module' with your actual service and module names.
    Examples:
    - gcp/iam/workload-identity/terraform.tfstate
    - gcp/networking/vpc-baseline/terraform.tfstate
    - gcp/security/encryption-baseline/terraform.tfstate
  EOT
}

output "github_secrets_config" {
  description = "GitHub repository secrets configuration"
  value = <<-EOT
    
    Add these secrets to your GitHub repository:
    
    GCP_PROJECT_ID: ${local.project_id}
    WIF_PROVIDER: ${google_iam_workload_identity_pool_provider.github.name}
    WIF_SERVICE_ACCOUNT: ${google_service_account.github_actions.email}
    
    Then use in your GitHub Actions workflow:
    
    - name: Authenticate to GCP
      uses: google-github-actions/auth@v2
      with:
        project_id: $${{ secrets.GCP_PROJECT_ID }}
        workload_identity_provider: $${{ secrets.WIF_PROVIDER }}
        service_account: $${{ secrets.WIF_SERVICE_ACCOUNT }}
  EOT
}

output "github_actions_workflow_example" {
  description = "Example GitHub Actions workflow configuration"
  value = <<-EOT
    
    # Example .github/workflows/deploy-gcp.yml
    name: Deploy to GCP
    
    on:
      push:
        branches: [main]
        paths: ['deployments/gcp/**']
    
    permissions:
      id-token: write   # Required for OIDC
      contents: read    # Required for checkout
    
    jobs:
      deploy:
        runs-on: ubuntu-latest
        steps:
          - name: Checkout code
            uses: actions/checkout@v4
    
          - name: Authenticate to GCP
            uses: google-github-actions/auth@v2
            with:
              project_id: $${{ secrets.GCP_PROJECT_ID }}
              workload_identity_provider: $${{ secrets.WIF_PROVIDER }}
              service_account: $${{ secrets.WIF_SERVICE_ACCOUNT }}
    
          - name: Setup Terraform
            uses: hashicorp/setup-terraform@v3
            with:
              terraform_version: 1.6.0
    
          - name: Terraform Init
            run: terraform init
    
          - name: Terraform Plan
            run: terraform plan
    
          - name: Terraform Apply
            if: github.ref == 'refs/heads/main'
            run: terraform apply -auto-approve
  EOT
}

output "local_development_setup" {
  description = "Commands for local development setup"
  value = <<-EOT
    
    Set up local development with Application Default Credentials:
    
    # Authenticate with GCP (one-time setup)
    gcloud auth login
    gcloud auth application-default login
    
    # Set project (replace with your project ID)
    gcloud config set project ${local.project_id}
    
    # Verify authentication
    gcloud auth list
    gcloud config list
    
    # Test GCS access
    gsutil ls gs://${google_storage_bucket.terraform_state.name}
    
    # Navigate to any module and run Terraform
    cd deployments/gcp/iam/workload-identity/
    terraform init
    terraform plan
  EOT
}

output "migration_instructions" {
  description = "Instructions for migrating bootstrap state to GCS"
  value = <<-EOT
    
    Migrate bootstrap state to remote GCS storage:
    
    1. Copy backend template:
       cp backend.tf.example backend.tf
    
    2. Update project ID in backend.tf:
       sed -i 's/PROJECT-ID/${local.project_id}/g' backend.tf
    
    3. Initialize backend migration:
       terraform init -migrate-state
    
    4. Confirm migration when prompted:
       Type: yes
    
    5. Verify remote state:
       gsutil ls gs://${google_storage_bucket.terraform_state.name}/bootstrap/
    
    6. Clean up local state files (optional):
       rm terraform.tfstate terraform.tfstate.backup
  EOT
}

output "cost_estimate" {
  description = "Monthly cost estimate for GCP resources"
  value = <<-EOT
    
    Estimated monthly costs:
    
    - GCS Bucket Storage: ~$0.02/GB/month (first 5GB free)
    - GCS Operations: ~$0.05/10K operations (generous free tier)
    - Workload Identity Federation: FREE
    - Service Account: FREE
    - IAM Operations: FREE
    
    Total for typical usage: $0.00/month (within free tier)
    
    Note: Costs may vary based on actual usage and state file sizes.
  EOT
}

output "cleanup_instructions" {
  description = "Instructions for cleaning up resources (development only)"
  value = <<-EOT
    
    ⚠️  WARNING: This will destroy all infrastructure!
    
    To clean up resources (development/testing only):
    
    1. Destroy dependent modules first:
       cd deployments/gcp/iam/workload-identity/
       terraform destroy
    
    2. Destroy bootstrap (this module):
       cd ../../bootstrap/state-storage/
       terraform destroy
    
    3. Manually delete GCS bucket if needed:
       gsutil rm -r gs://${google_storage_bucket.terraform_state.name}
    
    Note: Production state buckets have lifecycle prevent_destroy enabled.
  EOT
}