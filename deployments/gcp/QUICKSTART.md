# GCP Quick Start Guide

Get your GCP infrastructure up and running in 10 minutes! 🚀

## Prerequisites

- **Google Cloud CLI** installed and configured
- **Terraform** >= 1.0 installed
- **GCP Project** with billing enabled
- **Coffee** ☕ *(optional but highly recommended)*

## Step 1: Set Up GCP Authentication

### Install Google Cloud CLI (if not already installed)

**Windows (PowerShell):**
```powershell
winget install Google.CloudSDK
```

**macOS:**
```bash
brew install google-cloud-sdk
```

**Linux:**
```bash
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
```

### Authenticate with GCP

```bash
# Login to GCP
gcloud auth login

# Set up Application Default Credentials (for Terraform)
gcloud auth application-default login

# Set your project (replace with your actual project ID)
gcloud config set project YOUR-PROJECT-ID

# Verify setup
gcloud config list
gcloud projects describe $(gcloud config get-value project)
```

## Step 2: Bootstrap Terraform State Storage

```bash
# Navigate to bootstrap module
cd deployments/gcp/bootstrap/state-storage/

# Initialize Terraform (uses local state initially)
terraform init

# Review what will be created
terraform plan

# Create the GCS bucket and IAM resources
terraform apply
```

**What gets created:**
- **GCS Bucket:** `fictional-octo-system-tfstate-<PROJECT-ID>` (encrypted, versioned)
- **Service Account:** For GitHub Actions CI/CD
- **Workload Identity Pool:** `github-actions-pool` (organization-wide)
- **IAM Bindings:** Minimal permissions for state access

## Step 3: Migrate Bootstrap State to GCS

```bash
# Still in bootstrap/state-storage/ directory

# Copy the backend template
cp backend.tf.example backend.tf

# Update backend.tf with your project ID
# Replace PROJECT-ID with your actual project ID
sed -i 's/PROJECT-ID/your-actual-project-id/g' backend.tf

# Or edit manually:
# nano backend.tf

# Migrate state to GCS
terraform init -migrate-state

# Confirm migration when prompted
# Type: yes
```

## Step 4: Set Up GitHub Actions (Optional)

Add these secrets to your GitHub repository:

```bash
# Get the values from Terraform output
terraform output github_secrets_config
```

Add to GitHub repository secrets:
- `GCP_PROJECT_ID`: Your GCP project ID
- `WIF_PROVIDER`: Workload Identity Federation provider ID
- `WIF_SERVICE_ACCOUNT`: Service account email

## Step 5: Deploy Your First Module

```bash
# Navigate to workload identity module
cd ../../iam/workload-identity/

# Initialize with remote backend
terraform init

# Review and apply
terraform plan
terraform apply
```

## Step 6: Verify Everything Works

### Test Local Access
```bash
# Check GCS bucket access
gsutil ls gs://fictional-octo-system-tfstate-$(gcloud config get-value project)

# List Terraform state files
gsutil ls gs://fictional-octo-system-tfstate-$(gcloud config get-value project)/**
```

### Test GitHub Actions (if configured)
```bash
# Commit and push to trigger GitHub Actions
git add .
git commit -m "Add GCP infrastructure"
git push origin main
```

## What You Get Out of the Box

| Component | Purpose | Cost |
|-----------|---------|------|
| **GCS State Bucket** | Terraform state storage | **Free** (5GB included) |
| **Workload Identity** | GitHub Actions auth | **Free** |
| **Service Account** | CI/CD permissions | **Free** |
| **Organization Policies** | Security constraints | **Free** |

**Total Monthly Cost: $0.00** 🎉

## Next Steps

1. **Set up budgets:**
   ```bash
   cd cost-management/budgets/
   terraform apply
   ```

2. **Deploy networking:**
   ```bash
   cd networking/vpc-baseline/
   terraform apply
   ```

3. **Add secrets management:**
   ```bash
   cd secrets/secret-manager/
   terraform apply
   ```

## Common Issues & Solutions

### Issue: "Permission denied" during terraform apply
**Solution:**
```bash
# Re-authenticate
gcloud auth application-default login

# Verify project access
gcloud projects get-iam-policy $(gcloud config get-value project)
```

### Issue: "Backend initialization failed"
**Solution:**
```bash
# Check if bucket exists
gsutil ls gs://fictional-octo-system-tfstate-$(gcloud config get-value project)

# If not, run bootstrap first
cd bootstrap/state-storage/
terraform apply
```

### Issue: "Invalid project ID"
**Solution:**
```bash
# Check current project
gcloud config get-value project

# List available projects
gcloud projects list

# Set correct project
gcloud config set project YOUR-CORRECT-PROJECT-ID
```

### Issue: GitHub Actions failing
**Solution:**
```bash
# Check GitHub secrets are set correctly
terraform output github_secrets_config

# Verify Workload Identity Federation
gcloud iam workload-identity-pools list --location=global
```

## Cleanup (Development Only)

⚠️ **Warning:** This will delete all infrastructure!

```bash
# Destroy modules in reverse order
cd iam/workload-identity/
terraform destroy

cd ../../bootstrap/state-storage/
terraform destroy
```

## Multi-Cloud Integration

Your GCP setup integrates seamlessly with existing AWS and Azure infrastructure:

```bash
# Deploy AWS resources
cd ../../../aws/budgets/cost-management/
terraform apply

# Deploy Azure resources
cd ../../../azure/key-vault/
terraform apply

# Deploy GCP resources
cd ../../../gcp/secrets/secret-manager/
terraform apply
```

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   AWS (N.VA)    │    │ Azure (Sweden)  │    │  GCP (Finland)  │
│                 │    │                 │    │                 │
│ • S3 + DynamoDB │    │ • Blob Storage  │    │ • Cloud Storage │
│ • OIDC Provider │    │ • Managed ID    │    │ • Workload ID   │
│ • Secrets Mgr   │    │ • Key Vault     │    │ • Secret Mgr    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                               │
                    ┌─────────────────┐
                    │  GitHub Actions │
                    │   (OIDC Auth)   │
                    └─────────────────┘
```

---

**🎉 Congratulations!** You now have a fully configured GCP environment with:
- Secure, keyless authentication
- Remote state management
- GitHub Actions integration
- Multi-cloud compatibility

**Next:** Check out [README.md](README.md) for detailed architecture documentation!

Happy deploying! 🚀☁️