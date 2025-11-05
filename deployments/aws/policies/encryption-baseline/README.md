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
