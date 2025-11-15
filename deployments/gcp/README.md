# GCP Deployments

> *"Because sometimes you need three clouds to feel truly multi-cloud"* ☁️☁️☁️

## Overview

This directory contains Google Cloud Platform (GCP) deployment configurations using Terraform, designed to complement our existing AWS and Azure infrastructure. All deployments use the Finland region (`europe-north1`) for consistency with our Nordic preference and Application Default Credentials (ADC) for secure, keyless authentication.

## Quick Start

1. **Set up GCP authentication:**
   ```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud config set project YOUR-PROJECT-ID
   ```

2. **Bootstrap state storage:**
   ```bash
   cd bootstrap/state-storage/
   terraform init
   terraform apply
   # Follow migration guide to move state to GCS
   ```

3. **Deploy other modules:**
   ```bash
   cd ../iam/workload-identity/
   terraform init
   terraform apply
   ```

## Directory Structure

```
deployments/gcp/
├── README.md                    # This file
├── QUICKSTART.md               # 5-minute setup guide
├── .gitignore                  # GCP-specific ignores
│
├── bootstrap/                   # Initial setup (do this first!)
│   └── state-storage/          # GCS bucket for Terraform state
│
├── iam/                        # Identity & Access Management
│   └── workload-identity/      # GitHub Actions OIDC authentication
│
├── security/                   # Security & Compliance
│   ├── encryption-baseline/    # Encryption policies
│   ├── region-control/         # Organization policy constraints
│   └── security-baseline/      # Security Command Center policies
│
├── secrets/                    # Secret management
│   └── secret-manager/         # Google Secret Manager
│
├── cost-management/            # Cost control
│   └── budgets/               # GCP budgets and alerts
│
├── compute/                    # Compute resources
│   ├── gce-baseline/          # Google Compute Engine setup
│   └── gke-cluster/           # Google Kubernetes Engine
│
├── networking/                 # Network resources
│   ├── vpc-baseline/          # VPC setup with subnets
│   └── firewall-rules/        # Firewall management
│
├── storage/                   # Storage services
│   ├── cloud-storage/         # Cloud Storage buckets
│   └── cloud-sql/            # Cloud SQL instances
│
└── monitoring/                # Observability
    ├── logging/               # Cloud Logging setup
    └── monitoring/            # Cloud Monitoring
```

## Authentication Methods

> ⚠️ **Prerequisites**: Install [Google Cloud CLI](https://cloud.google.com/sdk/docs/install) first!
> 
> **Windows**: `winget install Google.CloudSDK`  
> **After install**: `gcloud auth login && gcloud config set project YOUR-PROJECT-ID`

### Local Development (Keyless)
Use Application Default Credentials for secure, keyless development:

```bash
# One-time setup (after installing gcloud CLI)
gcloud auth application-default login

# Verify credentials
gcloud auth application-default print-access-token
```

**Pros:**
- ✅ No service account keys to manage
- ✅ Automatic credential refresh
- ✅ Same security model as Azure CLI (`az login`)
- ✅ Works with all Terraform providers

### CI/CD (GitHub Actions)
Use Workload Identity Federation for passwordless GitHub Actions:

```yaml
- name: Authenticate to GCP
  uses: google-github-actions/auth@v2
  with:
    project_id: ${{ secrets.GCP_PROJECT_ID }}
    workload_identity_provider: ${{ secrets.WIF_PROVIDER }}
    service_account: ${{ secrets.WIF_SERVICE_ACCOUNT }}
```

**Pros:**
- ✅ No long-lived secrets in GitHub
- ✅ Short-lived tokens (1 hour max)
- ✅ Repository-specific access control
- ✅ Mirrors Azure OIDC approach

## Region Strategy

**Primary Region:** `europe-north1` (Finland)
- Consistent with AWS `eu-north-1` (Stockholm)
- Low latency for Nordic users
- Full GCP service availability
- GDPR compliant

**Secondary Region:** `europe-west1` (Belgium)
- Backup for disaster recovery
- Cross-region replication target

## State Management

### GCS Backend Configuration
```hcl
terraform {
  backend "gcs" {
    bucket = "fictional-octo-system-tfstate-PROJECT-ID"
    prefix = "gcp/service/module/terraform.tfstate"
  }
}
```

### State File Organization
```
GCS Bucket: fictional-octo-system-tfstate-<PROJECT-ID> (europe-north1)
├── bootstrap/terraform.tfstate              # Bootstrap module (migrated)
├── gcp/iam/workload-identity/              # GitHub Actions OIDC
├── gcp/security/encryption-baseline/       # Encryption policies
├── gcp/secrets/secret-manager/             # Secret Manager
├── gcp/cost-management/budgets/            # Budget alerts
└── gcp/networking/vpc-baseline/            # VPC networking
```

## Cost Management

### Free Tier Benefits
- **Cloud Storage:** 5 GB free monthly (permanent)
- **Cloud Build:** 120 build-minutes daily
- **Cloud Functions:** 2M invocations monthly
- **Compute Engine:** 1 e2-micro instance monthly
- **Secret Manager:** 6 secret versions monthly

### Budget Alerts
Set up budget alerts to avoid surprise charges:

```bash
cd cost-management/budgets/
terraform apply
```

## Security Best Practices

1. **Use Application Default Credentials** for local development
2. **Enable Organization Policies** for security constraints
3. **Use Workload Identity Federation** for CI/CD
4. **Encrypt everything** with customer-managed keys
5. **Monitor with Cloud Security Command Center**

## Multi-Cloud Comparison

| Feature | AWS | Azure | GCP |
|---------|-----|-------|-----|
| **State Storage** | S3 + DynamoDB | Blob Storage | Cloud Storage (built-in locking) |
| **Region** | eu-north-1 | swedencentral | europe-north1 |
| **Authentication** | OIDC | Managed Identity | Workload Identity Federation |
| **Secrets** | Secrets Manager | Key Vault | Secret Manager |
| **Cost Control** | Budgets | Cost Management | Billing Budgets |
| **Free Tier** | 12 months | 12 months + always free | Always free (more generous) |

## Getting Help

- **Quick Start:** [QUICKSTART.md](QUICKSTART.md)
- **Bootstrap Guide:** [bootstrap/state-storage/README.md](bootstrap/state-storage/README.md)
- **GCP Documentation:** https://cloud.google.com/docs
- **Terraform GCP Provider:** https://registry.terraform.io/providers/hashicorp/google/latest/docs

## Troubleshooting

### Authentication Issues
```bash
# Check current authentication
gcloud auth list
gcloud config list

# Re-authenticate if needed
gcloud auth application-default login
```

### Permission Issues
```bash
# Check project permissions
gcloud projects get-iam-policy PROJECT-ID

# Verify service account permissions
gcloud iam service-accounts get-iam-policy SA-EMAIL
```

### State Access Issues
```bash
# Check GCS bucket access
gsutil ls gs://fictional-octo-system-tfstate-PROJECT-ID

# Verify backend configuration
terraform init -backend-config="bucket=YOUR-BUCKET-NAME"
```

---

**Remember:** Bootstrap the state storage first, then deploy other modules! 🚀

Happy cloud computing! ☁️✨