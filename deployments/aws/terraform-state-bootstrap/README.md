# AWS Terraform State Storage Bootstrap

This directory contains a one-time setup to create the S3 bucket and DynamoDB table for storing Terraform state.

## Why Bootstrap?

You have a chicken-and-egg problem: You need an S3 bucket to store state, but you need Terraform to create the bucket. This module solves that by creating the bucket first without a backend, then you migrate to using it.

## Setup Process (✅ COMPLETED)

### Step 1: Create the State Storage ✅

```bash
cd deployments/aws/terraform-state-bootstrap/

# Initialize (uses local state initially)
terraform init

# Create the S3 bucket and DynamoDB table
terraform apply
```

This created:
- **S3 Bucket**: `fictional-octo-system-tfstate-494367313227` (encrypted, versioned, in **eu-north-1 Stockholm**)
- **DynamoDB Table**: `terraform-state-locks` (for state locking, in **eu-north-1**)
- **IAM Policy**: `TerraformStateAccess` (for access control)

### Step 2: Migrate Bootstrap State to S3 ✅

After creating the bucket, the bootstrap module's state was migrated to S3:

```bash
# Backend block uncommented in main.tf
terraform init -migrate-state
```

**Status**: Bootstrap state is now stored in `s3://fictional-octo-system-tfstate-494367313227/bootstrap/terraform.tfstate`

### Step 3: Use in Other Modules

Now all other AWS modules can use the S3 backend. The `encryption-baseline` module is ready to deploy:

```bash
cd ../policies/encryption-baseline/

# Copy example config
cp terraform.tfvars.example terraform.tfvars

# Initialize with S3 backend
terraform init

# Deploy AWS Config rules
terraform plan
terraform apply
```

This will create AWS Config rules for encryption compliance in **eu-north-1** (Stockholm).

## State File Organization

```
S3 Bucket: fictional-octo-system-tfstate-494367313227 (eu-north-1)
├── bootstrap/terraform.tfstate              # ✅ This module (migrated)
├── aws/policies/encryption-baseline/        # Encryption policies (ready to deploy)
├── aws/policies/region-control/             # Region control
├── aws/iam/github-oidc/                     # GitHub Actions OIDC
├── aws/kms/key-management/                  # KMS keys
└── aws/networking/vpc-baseline/             # VPC networking
```

## Comparison with Azure

Your Azure state is currently stored locally. This AWS setup uses remote state:

| Cloud | State Storage | Locking | Region |
|-------|--------------|---------|--------|
| Azure | Local files (should migrate to Azure Blob) | None | N/A |
| AWS   | S3 Bucket (✅ configured) | DynamoDB | eu-north-1 (Stockholm) |

**Note**: Consider migrating Azure state to Azure Blob Storage for consistency and team collaboration.

## Security Features

- **Encryption**: AES-256 encryption at rest
- **Versioning**: Previous state versions retained
- **Access Control**: IAM policies restrict access
- **Audit Logging**: S3 access logs and CloudTrail

## Cost

- **S3**: ~$0.023/GB/month (state files are tiny, <$0.01/month)
- **DynamoDB**: Free tier covers lock table (25 GB storage, 25 RCU/WCU)
- **Total**: Effectively free

## Cleanup

If you want to destroy everything later:

```bash
# First destroy all other modules
cd ../policies/encryption-baseline/
terraform destroy

# Then destroy the bootstrap
cd ../../terraform-state-bootstrap/
terraform destroy
```

⚠️ **Warning**: Destroying the bootstrap will delete your state bucket!
