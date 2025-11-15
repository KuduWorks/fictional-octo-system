output "project_id" {
  description = "GCP Project ID"
  value       = local.project_id
}

output "workload_identity_pool" {
  description = "Workload Identity Pool name"
  value       = google_iam_workload_identity_pool.github_actions.name
}

output "service_accounts" {
  description = "Service accounts created for GitHub repositories"
  value = {
    for k, v in google_service_account.github_repos : k => {
      email = v.email
      name  = v.name
      id    = v.id
    }
  }
}

output "workload_identity_providers" {
  description = "Workload Identity Federation providers for each repository"
  value = {
    for k, v in google_iam_workload_identity_pool_provider.github_repos : k => {
      name = v.name
      id   = v.workload_identity_pool_provider_id
    }
  }
}

output "github_secrets_config" {
  description = "GitHub repository secrets configuration for all repositories"
  value = {
    for k, repo in var.github_repositories : k => {
      repository_name = "${repo.org}/${repo.repo}"
      secrets = {
        GCP_PROJECT_ID      = local.project_id
        WIF_PROVIDER        = google_iam_workload_identity_pool_provider.github_repos[k].name
        WIF_SERVICE_ACCOUNT = google_service_account.github_repos[k].email
      }
    }
  }
}

output "github_actions_workflow_examples" {
  description = "Example GitHub Actions workflows for each repository"
  value = {
    for k, repo in var.github_repositories : k => <<-EOT
      # .github/workflows/deploy-gcp.yml for ${repo.org}/${repo.repo}
      name: Deploy to GCP
      
      on:
        push:
          branches: ${jsonencode(length(repo.branches) > 0 ? repo.branches : ["main"])}
          paths: ['deployments/gcp/**']
      
      permissions:
        id-token: write
        contents: read
      
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
}



output "configuration_summary" {
  description = "Summary of Workload Identity Federation configuration"
  value = {
    total_repositories = length(var.github_repositories)
    repositories = {
      for k, repo in var.github_repositories : k => {
        full_name       = "${repo.org}/${repo.repo}"
        branches        = length(repo.branches) > 0 ? repo.branches : ["all branches"]
        roles           = repo.roles
        custom_roles    = repo.custom_roles
        service_account = google_service_account.github_repos[k].email
      }
    }
    workload_identity_pool = google_iam_workload_identity_pool.github_actions.name
    authentication_method  = "Workload Identity Federation (OIDC)"
    security_benefits = [
      "No long-lived secrets",
      "Short-lived tokens (1 hour max)",
      "Repository and branch scoped access",
      "Automatic token rotation",
      "Audit trail via Cloud Logging"
    ]
  }
}

output "setup_instructions" {
  description = "Setup instructions for each repository"
  value = {
    for k, repo in var.github_repositories : k => {
      repository = "${repo.org}/${repo.repo}"
      steps = [
        "1. Add GitHub repository secrets:",
        "   - GCP_PROJECT_ID: ${local.project_id}",
        "   - WIF_PROVIDER: ${google_iam_workload_identity_pool_provider.github_repos[k].name}",
        "   - WIF_SERVICE_ACCOUNT: ${google_service_account.github_repos[k].email}",
        "2. Create workflow file: .github/workflows/deploy-gcp.yml",
        "3. Use the example workflow from github_actions_workflow_examples output",
        "4. Ensure workflow triggers on allowed branches: ${jsonencode(length(repo.branches) > 0 ? repo.branches : ["main"])}",
        "5. Test authentication by running workflow"
      ]
    }
  }
}

output "iam_roles_summary" {
  description = "Summary of IAM roles granted to each service account"
  value = {
    for k, repo in var.github_repositories : k => {
      service_account        = google_service_account.github_repos[k].email
      predefined_roles       = repo.roles
      custom_roles           = repo.custom_roles
      terraform_state_access = var.enable_terraform_state_access
    }
  }
}