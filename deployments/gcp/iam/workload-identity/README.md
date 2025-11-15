# GCP Workload Identity Federation

> *"Because trusting GitHub with your GCP keys is like giving your house keys to the internet"* 🔐☁️

This module extends the bootstrap Workload Identity Federation setup to configure multiple GitHub repositories with secure, keyless access to GCP resources.

## Overview

Workload Identity Federation allows GitHub Actions to authenticate with GCP without storing long-lived service account keys. This module:

- Creates service accounts for each GitHub repository
- Configures repository-specific Workload Identity providers
- Grants minimal IAM permissions based on repository needs
- Supports branch restrictions and environment-specific access
- Provides custom IAM role creation for fine-grained permissions

## Prerequisites

1. **Bootstrap module deployed**: The `bootstrap/state-storage` module must be deployed first to create the Workload Identity pool
2. **GCP authentication**: `gcloud auth application-default login` configured
3. **GitHub repositories**: Repositories you want to grant GCP access to

## Quick Start

### Step 1: Configure Repositories

```bash
# Copy configuration template
cp terraform.tfvars.example terraform.tfvars

# Edit configuration
nano terraform.tfvars
```

Add your repositories:
```hcl
github_repositories = {
  "main" = {
    org          = "YourOrg"
    repo         = "your-repo"
    display_name = "Your Application"
    branches     = ["main", "develop"]
    roles = [
      "roles/storage.objectAdmin",
      "roles/compute.viewer"
    ]
    custom_roles = []
  }
}
```

### Step 2: Deploy Module

```bash
# Copy backend configuration
cp backend.tf.example backend.tf

# Update with your project ID
sed -i 's/PROJECT-ID/your-project-id/g' backend.tf

# Deploy
terraform init
terraform apply
```

### Step 3: Configure GitHub Secrets

```bash
# Get configuration for each repository
terraform output github_secrets_config
```

Add these secrets to each GitHub repository:
- `GCP_PROJECT_ID`: Your GCP project ID
- `WIF_PROVIDER`: Workload Identity Federation provider
- `WIF_SERVICE_ACCOUNT`: Service account email

## Repository Configuration

### Basic Repository Setup

```hcl
github_repositories = {
  "app" = {
    org          = "MyOrg"              # GitHub organization
    repo         = "my-app"             # Repository name
    display_name = "My Application"     # Human-readable name
    branches     = ["main"]            # Allowed branches (empty = all)
    roles = [                          # IAM roles to grant
      "roles/run.admin",
      "roles/storage.admin"
    ]
    custom_roles = []                  # Custom roles (defined separately)
  }
}
```

### Multi-Environment Setup

```hcl
github_repositories = {
  "app-dev" = {
    org          = "MyOrg"
    repo         = "my-app"
    display_name = "My App (Development)"
    branches     = ["develop", "feature/*"]  # Development branches
    roles = ["roles/editor"]                  # Broad permissions for dev
    custom_roles = []
  },
  
  "app-prod" = {
    org          = "MyOrg"
    repo         = "my-app"
    display_name = "My App (Production)"
    branches     = ["main"]                   # Production branch only
    roles = [                                 # Minimal permissions
      "roles/run.admin",
      "roles/storage.objectUser"
    ]
    custom_roles = ["app_deployer"]
  }
}
```

## Custom IAM Roles

Create fine-grained permissions for specific use cases:

```hcl
custom_roles = {
  "terraform_deployer" = {
    title       = "Terraform Deployer"
    description = "Minimal permissions for Terraform deployments"
    stage       = "GA"
    permissions = [
      "compute.instances.create",
      "compute.instances.delete",
      "storage.buckets.create",
      "storage.buckets.delete"
    ]
  }
}
```

## GitHub Actions Integration

### Basic Workflow

```yaml
# .github/workflows/deploy-gcp.yml
name: Deploy to GCP

on:
  push:
    branches: [main]

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
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3

      - name: Terraform Deploy
        run: |
          terraform init
          terraform plan
          terraform apply -auto-approve
```

### Environment-Specific Workflow

```yaml
# Deploy to different environments based on branch
name: Deploy to GCP

on:
  push:
    branches: [main, develop]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set environment
        id: env
        run: |
          if [ "${{ github.ref }}" == "refs/heads/main" ]; then
            echo "env=prod" >> $GITHUB_OUTPUT
          else
            echo "env=dev" >> $GITHUB_OUTPUT
          fi

      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ secrets[format('WIF_PROVIDER_{0}', steps.env.outputs.env)] }}
          service_account: ${{ secrets[format('WIF_SERVICE_ACCOUNT_{0}', steps.env.outputs.env)] }}
```

## Security Features

### Repository Restrictions
- **Branch filtering**: Limit access to specific branches
- **Repository scoping**: Each provider is tied to a specific repository
- **Short-lived tokens**: Tokens expire after 1 hour
- **Audit logging**: All access is logged via Cloud Audit Logs

### IAM Best Practices
- **Principle of least privilege**: Grant minimal required permissions
- **Custom roles**: Use custom roles for fine-grained control
- **Service account separation**: Different service accounts per repository/environment
- **No long-lived keys**: Workload Identity Federation eliminates key management

## Terraform State Access

Enable Terraform state bucket access:

```hcl
enable_terraform_state_access = true
terraform_state_bucket = "fictional-octo-system-tfstate-PROJECT-ID"
```

This grants `roles/storage.objectAdmin` on the state bucket to all configured service accounts.

## Common IAM Role Patterns

### Application Deployment
```hcl
roles = [
  "roles/run.admin",              # Cloud Run services
  "roles/storage.admin",          # Application storage
  "roles/cloudsql.client",        # Database access
  "roles/secretmanager.accessor"  # Application secrets
]
```

### Infrastructure Management
```hcl
roles = [
  "roles/compute.instanceAdmin",   # VM management
  "roles/iam.serviceAccountAdmin", # Service account management
  "roles/resourcemanager.projectIamAdmin", # Project IAM
  "roles/storage.admin"            # Terraform state storage
]
```

### Data Pipeline
```hcl
roles = [
  "roles/bigquery.admin",         # BigQuery datasets
  "roles/dataflow.admin",         # Dataflow jobs
  "roles/storage.objectAdmin",     # Data lake storage
  "roles/pubsub.admin"            # Pub/Sub topics
]
```

## Troubleshooting

### Authentication Errors

**Error**: `Error: Failed to get existing workloads`

**Cause**: Workload Identity pool doesn't exist

**Solution**:
```bash
# Deploy bootstrap module first
cd ../../bootstrap/state-storage/
terraform apply

# Verify pool exists
gcloud iam workload-identity-pools list --location=global
```

### Permission Denied

**Error**: `Permission denied on resource`

**Cause**: Insufficient IAM permissions

**Solution**:
1. Check service account has required roles:
   ```bash
   gcloud projects get-iam-policy PROJECT-ID --filter="bindings.members:serviceAccount:github-*"
   ```

2. Add missing permissions:
   ```hcl
   roles = [
     "roles/existing.role",
     "roles/missing.role"  # Add this
   ]
   ```

### GitHub Actions Failures

**Error**: `failed to generate access token`

**Cause**: Incorrect GitHub secrets or repository configuration

**Solution**:
1. Verify GitHub secrets match Terraform outputs:
   ```bash
   terraform output github_secrets_config
   ```

2. Check repository name in configuration:
   ```hcl
   github_repositories = {
     "main" = {
       org  = "CorrectOrg"     # Must match exactly
       repo = "correct-repo"   # Must match exactly
       # ...
     }
   }
   ```

3. Verify workflow permissions:
   ```yaml
   permissions:
     id-token: write  # Required
     contents: read   # Required
   ```

### Branch Restrictions

**Error**: `Token request failed` for specific branches

**Cause**: Branch not allowed in Workload Identity configuration

**Solution**:
1. Check allowed branches:
   ```bash
   terraform output configuration_summary
   ```

2. Add branch to configuration:
   ```hcl
   branches = ["main", "develop", "feature/new-branch"]
   ```

3. Or allow all branches:
   ```hcl
   branches = []  # Empty list allows all branches
   ```

## Cost Considerations

- **Workload Identity Federation**: FREE
- **Service Accounts**: FREE
- **IAM Operations**: FREE
- **Custom Roles**: FREE (up to 300 per project)
- **Cloud Audit Logs**: May incur storage costs for high-volume logging

**Total Monthly Cost: $0.00** for typical usage

## Integration Examples

### Deploy to Cloud Run

```yaml
- name: Deploy to Cloud Run
  run: |
    gcloud run deploy my-service \
      --image gcr.io/${{ secrets.GCP_PROJECT_ID }}/my-app:latest \
      --platform managed \
      --region europe-north1
```

### Terraform Deployment

```yaml
- name: Terraform Deployment
  run: |
    terraform init \
      -backend-config="bucket=fictional-octo-system-tfstate-${{ secrets.GCP_PROJECT_ID }}"
    terraform plan
    terraform apply -auto-approve
```

### Multi-Cloud Deployment

```yaml
- name: Deploy to all clouds
  run: |
    # Deploy to GCP
    terraform -chdir=deployments/gcp/compute/ apply -auto-approve
    
    # Deploy to AWS (separate workflow/job)
    # terraform -chdir=deployments/aws/compute/ apply -auto-approve
    
    # Deploy to Azure (separate workflow/job)
    # terraform -chdir=deployments/azure/compute/ apply -auto-approve
```

## Next Steps

1. **Deploy Security Policies**: Configure organization policies and security baselines
2. **Set Up Monitoring**: Deploy Cloud Monitoring and alerting
3. **Add Secret Management**: Configure Secret Manager for application secrets
4. **Cost Management**: Set up budgets and billing alerts

---

**Security Benefits** 🔒:
- No service account keys to manage or rotate
- Short-lived access tokens (1 hour maximum)
- Repository and branch-specific access control
- Full audit trail via Cloud Audit Logs
- Automatic credential rotation

**Ready for production!** 🚀

Happy secure deployments! 🔐✨