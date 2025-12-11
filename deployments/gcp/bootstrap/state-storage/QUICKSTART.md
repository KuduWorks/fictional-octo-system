# GCP Bootstrap Quick Start Guide

Get GCP Terraform state storage set up in 5 minutes! 🚀

## What You'll Get

- **GCS Bucket** for Terraform state (encrypted, versioned)
- **Service Account** for GitHub Actions CI/CD
- **Workload Identity Federation** for secure, keyless authentication
- **Organization-wide Identity Pool** for consistent access across projects

## Prerequisites

✅ Google Cloud CLI installed  
✅ GCP Project with billing enabled  
✅ Terraform >= 1.0 installed  

## Step 1: Authenticate with GCP

```bash
# Login and set up Application Default Credentials
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project <YOUR-PROJECT-ID>

# Verify setup
gcloud config list
```

## Step 2: Configure Your Setup

```bash
# Navigate to bootstrap directory
cd deployments/gcp/bootstrap/state-storage/

# Copy configuration template
cp terraform.tfvars.example terraform.tfvars

# Edit configuration (optional - defaults work fine)
nano terraform.tfvars
```

**Key settings to verify:**
```hcl
github_org = "KuduWorks"                    # Your GitHub org
github_repo = "fictional-octo-system"       # Your repository
environment = "dev"                         # Environment name
```

## Step 3: Deploy Bootstrap Infrastructure

```bash
# Initialize Terraform (local state initially)
terraform init

# Review what will be created
terraform plan

# Deploy the infrastructure
terraform apply
```

**Type `yes` when prompted.**

## Step 4: Migrate State to GCS

```bash
# Copy backend template
cp backend.tf.example backend.tf

# Update with your project ID (replace <YOUR-PROJECT-ID>)
sed -i 's/<YOUR-PROJECT-ID>/your-actual-project-id/g' backend.tf

# Migrate local state to GCS
terraform init -migrate-state
```

**Type `yes` when asked to migrate state.**

## Step 5: Set Up GitHub Actions (Optional)

```bash
# Get GitHub secrets configuration
terraform output github_secrets_config
```

Add these secrets to your GitHub repository:
- `GCP_PROJECT_ID`: Your GCP project ID
- `WIF_PROVIDER`: Workload Identity Federation provider
- `WIF_SERVICE_ACCOUNT`: Service account email

## Step 6: Verify Everything Works

### Test Local Access
```bash
# List GCS bucket contents
gsutil ls gs://fictional-octo-system-tfstate-$(gcloud config get-value project)

# Verify Terraform can access remote state
terraform state list
```

### Test Backend Configuration
```bash
# Check backend configuration
terraform show
```

## What Gets Created

| Resource | Purpose | Cost |
|----------|---------|------|
| **GCS Bucket** | Terraform state storage | **FREE** (5GB included) |
| **Service Account** | GitHub Actions authentication | **FREE** |
| **Workload Identity Pool** | Secure CI/CD access | **FREE** |
| **IAM Bindings** | Minimal permissions | **FREE** |

**Total Monthly Cost: $0.00** 🎉

## Next Steps

### Deploy Other GCP Modules
```bash
# Navigate to any other module
cd ../../iam/workload-identity/

# Initialize with remote backend
terraform init

# Deploy
terraform apply
```

### Set Up Cost Management
```bash
cd ../../cost-management/budgets/
terraform init
terraform apply
```

### Configure Security Policies
```bash
cd ../../security/encryption-baseline/
terraform init
terraform apply
```

## Testing Your Setup

### Verify GCS Access
```bash
# Check bucket permissions
gsutil iam get gs://fictional-octo-system-tfstate-$(gcloud config get-value project)

# List all state files
gsutil ls -r gs://fictional-octo-system-tfstate-$(gcloud config get-value project)
```

### Verify Workload Identity
```bash
# List Workload Identity pools
gcloud iam workload-identity-pools list --location=global

# Check service account
gcloud iam service-accounts list --filter="email:github-actions*"
```

## Common Issues & Quick Fixes

### Issue: "Permission denied" during apply
**Quick Fix:**
```bash
# Re-authenticate
gcloud auth application-default login
terraform apply
```

### Issue: "Bucket name already exists"
**Quick Fix:**
```bash
# Add unique suffix to bucket name in terraform.tfvars
state_bucket_name = "fictional-octo-system-tfstate-$(date +%s)"
terraform apply
```

### Issue: "API not enabled"
**Quick Fix:**
```bash
# APIs are enabled automatically, but you can force enable:
gcloud services enable storage.googleapis.com iam.googleapis.com
terraform apply
```

### Issue: GitHub Actions not working
**Quick Fix:**
```bash
# Verify GitHub secrets are correct
terraform output github_secrets_config

# Check repository name matches
echo "Current repo: $(git remote get-url origin)"
```

## GitHub Actions Workflow Example

Create `.github/workflows/deploy-gcp.yml`:

```yaml
name: Deploy GCP Infrastructure

on:
  push:
    branches: [main]
    paths: ['deployments/gcp/**']

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      
      - name: Terraform Init
        run: terraform init
        working-directory: deployments/gcp/iam/workload-identity
      
      - name: Terraform Apply
        run: terraform apply -auto-approve
        working-directory: deployments/gcp/iam/workload-identity
```

## Multi-Cloud Integration

Your setup now works alongside AWS and Azure:

```bash
# Deploy to all three clouds
cd deployments/aws/budgets/cost-management/ && terraform apply
cd deployments/azure/key-vault/ && terraform apply  
cd deployments/gcp/secrets/secret-manager/ && terraform apply
```

## Cleanup (Development Only)

⚠️ **Warning**: This destroys all infrastructure!

```bash
# Destroy in reverse dependency order
cd deployments/gcp/iam/workload-identity/
terraform destroy

cd ../../bootstrap/state-storage/
terraform destroy
```

## Architecture Overview

```
┌─────────────────────┐    ┌─────────────────────┐
│   Local Development │    │   GitHub Actions    │
│                     │    │                     │
│ • gcloud auth ADC   │    │ • Workload Identity │
│ • No service keys   │    │ • Short-lived tokens│
│ • Automatic refresh │    │ • Repository-scoped │
└──────────┬──────────┘    └──────────┬──────────┘
           │                          │
           └─────────┬──────────────────┘
                     │
         ┌─────────────────────┐
         │   GCS State Bucket  │
         │  (europe-north1)    │
         │                     │
         │ • Encrypted storage │
         │ • Versioned history │
         │ • Built-in locking  │
         │ • Audit logging     │
         └─────────────────────┘
```

---

**🎉 Success!** You now have:
- Secure, keyless GCP authentication
- Remote Terraform state storage
- GitHub Actions CI/CD ready
- Multi-cloud compatibility

**Next**: Deploy your first GCP module or check the [main README](../../../README.md)!

Happy deploying! 🚀☁️