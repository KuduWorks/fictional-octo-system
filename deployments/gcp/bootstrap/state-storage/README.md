# GCP Terraform State Storage Bootstrap

> *"Because even Terraform needs a place to store its memories"* 🧠💾

This directory contains a one-time setup to create the GCS bucket, service account, and Workload Identity Federation for storing Terraform state and enabling secure CI/CD.

## Why Bootstrap?

You have a chicken-and-egg problem: You need a GCS bucket to store state, but you need Terraform to create the bucket. This module solves that by creating the bucket first without a backend, then you migrate to using it.

## Important: Backend Configuration

⚠️ **Before using this module**, you need to configure the backend migration:

The backend configuration in `backend.tf.example` contains a placeholder `<YOUR-PROJECT-ID>` that serves as a template. Since Terraform backend blocks don't support variables, you must **manually update** the bucket name before migrating state to GCS.

**Option 1: Recommended for first-time setup**
Comment out the entire backend block initially, create the infrastructure, then configure and migrate it.

**Option 2: If you know your GCP project ID**
Update the bucket name in `backend.tf.example` with your project ID before starting.

## Setup Process

### Prerequisites

1. **Google Cloud CLI** installed and configured
2. **GCP Project** with billing enabled
3. **Terraform** >= 1.0 installed
4. **Required APIs** will be enabled automatically

### Step 1: Authenticate with GCP

```bash
# Login to GCP (one-time setup)
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project <YOUR-PROJECT-ID>

# Verify setup
gcloud config list
```

### Step 2: Create the State Storage

```bash
cd deployments/gcp/bootstrap/state-storage/

# Initialize (uses local state initially)
terraform init

# Review the plan
terraform plan

# Create the GCS bucket, service account, and Workload Identity
terraform apply
```

This will create:
- **GCS Bucket**: `fictional-octo-system-tfstate-<your-project-id>` (encrypted, versioned)
- **Service Account**: `github-actions-terraform@PROJECT.iam.gserviceaccount.com`
- **Workload Identity Pool**: `github-actions-pool` (organization-wide)
- **IAM Bindings**: Minimal permissions for state access

**Note the bucket name** from the output - you'll need it for the next step.

### Step 3: Migrate State to GCS

```bash
# Still in bootstrap/state-storage/ directory

# Copy the backend template
cp backend.tf.example backend.tf

# Update with your actual project ID
# Replace <YOUR-PROJECT-ID> with your project (e.g., my-gcp-project-123456)
sed -i 's/<YOUR-PROJECT-ID>/your-actual-project-id/g' backend.tf

# Or edit manually if you prefer
# nano backend.tf

# Initialize backend migration
terraform init -migrate-state
```

Terraform will ask: **"Do you want to copy existing state to the new backend?"**
- Type: `yes`

Your state is now stored remotely in GCS! 🎉

## Example: Completed Setup

After successful deployment, you'll have:

### GCS Bucket Structure
```
gs://fictional-octo-system-tfstate-<project-id>/ (europe-north1)
├── bootstrap/terraform.tfstate              # This module (migrated)
├── gcp/iam/workload-identity/              # Future modules
├── gcp/security/encryption-baseline/       # Security policies
├── gcp/secrets/secret-manager/             # Secret Manager
└── gcp/networking/vpc-baseline/            # VPC networking
```

### GitHub Actions Integration
```yaml
# .github/workflows/deploy-gcp.yml
name: Deploy to GCP

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    steps:
      - name: Authenticate to GCP
        uses: google-github-actions/auth@v2
        with:
          project_id: ${{ secrets.GCP_PROJECT_ID }}
          workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
          service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```

## State File Organization

```
GCS Bucket: fictional-octo-system-tfstate-<project-id> (europe-north1)
├── bootstrap/terraform.tfstate              # Bootstrap module
├── gcp/iam/workload-identity/              # GitHub Actions OIDC
├── gcp/security/encryption-baseline/       # Security policies
├── gcp/secrets/secret-manager/             # Secret Manager
├── gcp/cost-management/budgets/            # Budget alerts
└── gcp/networking/vpc-baseline/            # VPC networking
```

## Comparison with AWS/Azure

Your multi-cloud state management:

| Cloud | State Storage | Locking | Region | Authentication |
|-------|--------------|---------|--------|-----------------|
| AWS   | S3 + DynamoDB | DynamoDB | eu-north-1 | OIDC Provider |
| Azure | Blob Storage | Native | swedencentral | Managed Identity |
| GCP   | Cloud Storage | Native ✅ | europe-north1 | Workload Identity |

**GCP Advantages:**
- Built-in state locking (no separate service needed)
- 5GB free storage (permanent, vs AWS 12-month limit)
- Workload Identity Federation (more secure than service account keys)

## Security Features

- **Encryption**: Google-managed or customer-managed keys
- **Versioning**: Previous state versions retained for recovery
- **Access Control**: Minimal IAM permissions (storage.objectAdmin only)
- **Audit Logging**: Optional GCS access logs
- **Public Access**: Blocked by default
- **Uniform Bucket Access**: Consistent IAM-based access control

## Authentication Methods

### Local Development
```bash
# One-time setup - no service account keys needed!
gcloud auth application-default login

# Terraform automatically uses these credentials
terraform init
terraform plan
```

### GitHub Actions CI/CD
```yaml
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    project_id: ${{ secrets.GCP_PROJECT_ID }}
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```

## Cost

- **GCS Storage**: ~$0.020/GB/month (first 5GB free permanently)
- **GCS Operations**: ~$0.05/10K operations (generous free tier)
- **Workload Identity Federation**: FREE
- **Service Account**: FREE
- **IAM Operations**: FREE

**Total for typical usage: $0.00/month** (within free tier)

## Configuration Options

### Basic Configuration (Recommended Start)
```hcl
environment = "dev"
gcp_region = "europe-north1"
github_org = "<your-github-org>"
github_repo = "<your-repo-name>"
```

**Cost**: $0.00/month

### Production Configuration
```hcl
environment = "prod"
gcp_region = "europe-north1"
enable_audit_logging = true
state_version_retention_days = 365
kms_key_name = "projects/PROJECT/locations/europe-north1/keyRings/terraform-state/cryptoKeys/state-bucket"
```

**Cost**: ~$1.00/month (KMS key + audit logs)

## Terraform Backend Configuration

To use remote state storage in other modules:

1. **Add backend configuration to your module:**
   ```hcl
   terraform {
     backend "gcs" {
       bucket = "fictional-octo-system-tfstate-<YOUR-PROJECT-ID>"
       prefix = "gcp/service/module/terraform.tfstate"
     }
   }
   ```

2. **Initialize the backend:**
   ```bash
   terraform init
   ```

## Troubleshooting

### Error: "Permission denied"
**Cause**: Not authenticated with GCP

**Solution**:
```bash
gcloud auth application-default login
gcloud config set project <YOUR-PROJECT-ID>
```

### Error: "Bucket already exists"
**Cause**: Bucket names are globally unique across all GCP

**Solution**: Choose a different bucket name in `terraform.tfvars`:
```hcl
state_bucket_name = "my-unique-tfstate-bucket-name"
```

### Error: "API not enabled"
**Cause**: Required GCP APIs are not enabled

**Solution**: APIs are enabled automatically, but you can manually enable:
```bash
gcloud services enable storage.googleapis.com
gcloud services enable iam.googleapis.com
gcloud services enable iamcredentials.googleapis.com
```

### Error: "Workload Identity Federation failed"
**Cause**: GitHub repository configuration mismatch

**Solution**: Verify GitHub org/repo in `terraform.tfvars`:
```hcl
github_org = "YourActualGitHubOrg"
github_repo = "your-actual-repo-name"
```

## Integration with Other Modules

### Deploy Workload Identity
```bash
cd ../../iam/workload-identity/
terraform init
terraform apply
```

### Deploy Security Baseline
```bash
cd ../../security/encryption-baseline/
terraform init
terraform apply
```

### Deploy Budget Management
```bash
cd ../../cost-management/budgets/
terraform init
terraform apply
```

## Cleanup

⚠️ **Warning**: This will destroy all state storage and dependent resources!

```bash
# Destroy dependent modules first
cd ../../iam/workload-identity/
terraform destroy

# Then destroy bootstrap
cd ../../bootstrap/state-storage/
terraform destroy
```

**Note**: Production buckets have `prevent_destroy` enabled for safety.

## Next Steps

1. **Set up GitHub Actions**: Add secrets from `terraform output github_secrets_config`
2. **Deploy IAM module**: Configure Workload Identity for your repositories
3. **Add budget alerts**: Monitor GCP spending with cost management
4. **Deploy security baseline**: Implement organization policies and encryption

---

**Remember**: This is a one-time setup. Once configured, all other GCP modules will use this remote state storage! 🚀

Happy cloud computing! ☁️✨