# AWS Encryption Baseline Policies

This module mirrors the Azure ISO 27001 cryptography policies using AWS Config rules and Service Control Policies.

## What This Creates

### AWS Config Rules
- **s3-bucket-server-side-encryption-enabled** - Ensures S3 buckets have encryption enabled
- **encrypted-volumes** - Ensures EBS volumes are encrypted
- **rds-storage-encrypted** - Ensures RDS instances use encryption
- **s3-bucket-ssl-requests-only** - Ensures S3 requires HTTPS
- **dynamodb-table-encrypted-kms** - Ensures DynamoDB uses KMS encryption
- **cloudtrail-encryption-enabled** - Ensures CloudTrail logs are encrypted

### Optional SCPs (if using AWS Organizations)
- Deny creation of unencrypted S3 buckets
- Deny creation of unencrypted EBS volumes
- Require KMS CMK (not AWS-managed keys)

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
- For SCPs: AWS Organizations with appropriate permissions
- IAM permissions to create Config rules and roles

## Variables

See `variables.tf` for configuration options:
- `enable_scps` - Whether to create Service Control Policies (requires Organizations)
- `config_recorder_name` - Name of the AWS Config recorder
- `remediation_enabled` - Enable automatic remediation for non-compliant resources

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
