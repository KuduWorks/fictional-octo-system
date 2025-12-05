# AWS Terraform State Storage Bootstrap

This directory contains a one-time setup to create the S3 bucket and DynamoDB table for storing Terraform state.

## Why Bootstrap?

You have a chicken-and-egg problem: You need an S3 bucket to store state, but you need Terraform to create the bucket. This module solves that by creating the bucket first without a backend, then you migrate to using it.

## Important: Backend Configuration

⚠️ **Before using this module**, you need to configure the backend in `main.tf`:

The backend configuration (lines 11-32 in `main.tf`) contains a hardcoded AWS account ID that serves as an example. Since Terraform backend blocks don't support variables, you must **manually update** the bucket name before migrating state to S3.

**Option 1: Recommended for first-time setup**
Comment out the entire backend block initially, create the infrastructure, then uncomment and configure it.

**Option 2: If you know your AWS account ID**
Update the bucket name in the backend block to include your account ID before starting.

## Setup Process

This is a one-time setup that creates the foundational infrastructure for storing Terraform state in AWS.

### Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Access to create S3 buckets and DynamoDB tables
- Your AWS account ID (run `aws sts get-caller-identity --query Account --output text`)

### Step 1: Prepare Backend Configuration

**Edit `main.tf`** and either:
- Comment out the entire `backend "s3"` block (lines 11-32), OR
- Update the bucket name on line 26 with your AWS account ID: `fictional-octo-system-tfstate-<YOUR-ACCOUNT-ID>`

### Step 2: Create the State Storage

```bash
cd deployments/aws/terraform-state-bootstrap/

# Initialize (uses local state if backend is commented out)
terraform init

# Review the plan
terraform plan

# Create the S3 bucket and DynamoDB table
terraform apply
```

This will create:
- **S3 Bucket**: `fictional-octo-system-tfstate-<your-account-id>` (encrypted, versioned)
- **DynamoDB Table**: `terraform-state-locks` (for state locking)
- **IAM Policy**: `TerraformStateAccess` (for access control)

**Note the bucket name** from the output - you'll need it for the next step.

### Step 3: Migrate Bootstrap State to S3

After creating the bucket, migrate the bootstrap module's state to S3:

```bash
# 1. Update main.tf: Uncomment the backend block (if commented)
#    and ensure the bucket name matches the created bucket

# 2. Migrate the state
terraform init -migrate-state

# When prompted, type 'yes' to confirm migration
```

The bootstrap state will now be stored in S3 at `bootstrap/terraform.tfstate`.

### Step 3: Configure Other Modules

Other AWS modules can now use the S3 backend. Example for the encryption baseline:

```bash
cd ../policies/encryption-baseline/

# Copy and configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your settings

# Initialize with S3 backend
terraform init

# Deploy
terraform plan
terraform apply
```

## Example: Completed Setup

Below is an example of what a completed setup looks like. **Note**: The account ID shown (`123456789012`) is an example - replace with your own AWS account ID.

### Step 1: Create the State Storage ✅

```bash
cd deployments/aws/terraform-state-bootstrap/

# Initialize (uses local state initially)
terraform init

# Create the S3 bucket and DynamoDB table
terraform apply
```

This created:
- **S3 Bucket**: `fictional-octo-system-tfstate-<account-id>` (encrypted, versioned, in **eu-north-1 Stockholm**)
- **DynamoDB Table**: `terraform-state-locks` (for state locking, in **eu-north-1**)
- **IAM Policy**: `TerraformStateAccess` (for access control)

### Step 2: Migrate Bootstrap State to S3 ✅

After creating the bucket, the bootstrap module's state was migrated to S3:

```bash
# Backend block uncommented in main.tf
terraform init -migrate-state
```

**Example Status**: Bootstrap state stored in `s3://fictional-octo-system-tfstate-123456789012/bootstrap/terraform.tfstate` (replace `123456789012` with your account ID)

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
S3 Bucket: fictional-octo-system-tfstate-<YOUR-ACCOUNT-ID> (eu-north-1)
├── bootstrap/terraform.tfstate              # This module (migrated)
├── aws/policies/encryption-baseline/        # Encryption policies
├── aws/policies/region-control/             # Region control
├── aws/iam/github-oidc/                     # GitHub Actions OIDC
├── aws/kms/key-management/                  # KMS keys
└── aws/networking/vpc-baseline/             # VPC networking
```

**Note**: Replace `<YOUR-ACCOUNT-ID>` with your actual AWS account ID throughout your configuration.

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
