# AWS Encryption Baseline Policies

This module mirrors the Azure ISO 27001 cryptography policies using AWS Config rules and Service Control Policies.

## What This Creates

### AWS Config Rules (Detection Layer)
- **s3-bucket-server-side-encryption-enabled** - Ensures S3 buckets have encryption enabled
- **s3-bucket-ssl-requests-only** - Ensures S3 requires HTTPS
- **s3-bucket-public-read-prohibited** - Detects S3 buckets allowing public read access
- **s3-bucket-public-write-prohibited** - Detects S3 buckets allowing public write access
- **s3-account-level-public-access-blocks-periodic** - Verifies account-level public access blocks
- **encrypted-volumes** - Ensures EBS volumes are encrypted
- **rds-storage-encrypted** - Ensures RDS instances use encryption
- **dynamodb-table-encrypted-kms** - Ensures DynamoDB uses KMS encryption
- **cloudtrail-encryption-enabled** - Ensures CloudTrail logs are encrypted

### Service Control Policies (Prevention Layer)
When `enable_scps = true`, creates preventive controls:

**DenyS3PublicAccess SCP** - Prevents S3 buckets from being made public:
- ❌ Blocks deletion of public access blocks
- ❌ Blocks weakening public access block settings
- ❌ Denies public ACLs (public-read, public-read-write, authenticated-read)
- ❌ Denies public bucket policies
- ✅ Allows private buckets with proper access controls

### Account-Level Protection
- **S3 Account Public Access Block** - Enforces public access blocking at account level
  - `BlockPublicAcls = true`
  - `BlockPublicPolicy = true`
  - `IgnorePublicAcls = true`
  - `RestrictPublicBuckets = true`

## How It Works

This module implements **defense in depth** with multiple layers:

1. **Account-Level Block** (Layer 1) - Prevents public access by default
2. **Service Control Policies** (Layer 2) - Organization-level enforcement (when enabled)
3. **AWS Config Rules** (Layer 3) - Continuous compliance monitoring

### Detection vs Prevention

| Control Type | When It Acts | Can Be Bypassed? |
|-------------|-------------|------------------|
| **SCP** (Prevention) | Before resource creation | No - Hard block |
| **Account Block** | Before resource creation | No - Hard block |
| **Config Rules** (Detection) | After resource creation | Yes - Detects violations |

## Azure Equivalents

| AWS Config Rule | Azure Policy |
|----------------|--------------|
| s3-bucket-server-side-encryption-enabled | Storage account encryption (built-in) |
| encrypted-volumes | Disk encryption (custom policy) |
| rds-storage-encrypted | SQL TDE encryption |
| s3-bucket-ssl-requests-only | Storage HTTPS requirement |

## Usage

```bash
terraform init
terraform plan
terraform apply
```

## Prerequisites

- AWS Config must be enabled in your account/region
- For SCPs: AWS Organizations with Service Control Policies enabled
- IAM permissions to create Config rules and roles
- Management account access (for creating/attaching SCPs)

### Enabling Service Control Policies

If SCPs are not enabled in your organization:

```bash
# Get your organization root ID
ROOT_ID=$(aws organizations list-roots --query 'Roots[0].Id' --output text)

# Enable SCPs
aws organizations enable-policy-type --root-id $ROOT_ID --policy-type SERVICE_CONTROL_POLICY
```

## Variables

See `variables.tf` for configuration options:
- `enable_scps` - Whether to create Service Control Policies (requires Organizations) - **Set to `true` for enforcement**
- `config_recorder_name` - Name of the AWS Config recorder
- `remediation_enabled` - Enable automatic remediation for non-compliant resources
- `aws_region` - AWS region (default: `eu-north-1` Stockholm)
- `environment` - Environment name (default: `prod`)

## SCP Propagation

⏳ **Important**: After deploying SCPs, allow **5-15 minutes** for policies to propagate to all AWS regions and endpoints. During this time, some operations may not be immediately blocked.

## Testing Your Config Rules

Use the `test-config-rules.sh` script to validate that your Config rules are working correctly.

### Test Script Usage

```bash
# Basic usage
./test-config-rules.sh

# Specify region (if different from AWS CLI default)
AWS_REGION=eu-north-1 ./test-config-rules.sh
```

### What the Test Does

1. **Creates test resources** in both compliant and non-compliant configurations
2. **Waits for Config evaluation** (60 seconds for rules to evaluate)
3. **Checks compliance status** for each Config rule
4. **Generates a report** showing which rules are working
5. **Automatically cleans up** all test resources

### Important Notes

- **Automatic cleanup**: Script automatically deletes all test resources when finished
- **Region compatibility**: Ensure you're running in a region allowed by your policies  
- **Cost implications**: Test resources may incur minimal charges during test period
- **RDS instances**: Take several minutes to create/delete - be patient

### Test Results Interpretation

- **WORKING**: Rule correctly identifies non-compliant resources ✅
- **PARTIAL**: Rule found only compliant resources (may still be working) ⚠️
- **ERROR**: Rule not found or not evaluating ❌

### Prerequisites for Testing

- AWS CLI configured with appropriate credentials
- AWS Config enabled in your target region
- Permissions to create/delete test resources (S3, EBS, RDS, DynamoDB, CloudTrail, KMS)

### Region Compatibility

If you have region restrictions (e.g., Stockholm region only):

```bash
# Set your AWS CLI default region (recommended)
aws configure set region eu-north-1

# Or specify region when running
AWS_REGION=eu-north-1 ./test-config-rules.sh
```
