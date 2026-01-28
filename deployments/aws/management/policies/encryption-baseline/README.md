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
- **rds-storage-encrypted** - Ensures RDS instances use encryption at rest
- **dynamodb-table-encrypted-kms** - Ensures DynamoDB uses KMS encryption
- **cloudtrail-encryption-enabled** - Ensures CloudTrail logs are encrypted

### RDS Parameter Groups (SSL/TLS Enforcement)
Pre-configured parameter groups that enforce SSL/TLS connections for **all supported versions**:

**PostgreSQL (12, 13, 14, 15, 16)**
- `postgresql-postgres12-ssl-required`
- `postgresql-postgres13-ssl-required`
- `postgresql-postgres14-ssl-required`
- `postgresql-postgres15-ssl-required`
- `postgresql-postgres16-ssl-required`

**MySQL (5.7, 8.0)**
- `mysql-mysql57-ssl-required`
- `mysql-mysql80-ssl-required`

**Aurora PostgreSQL (13, 14, 15, 16)**
- `aurora-postgresql13-ssl-required`
- `aurora-postgresql14-ssl-required`
- `aurora-postgresql15-ssl-required`
- `aurora-postgresql16-ssl-required`

**Aurora MySQL (5.7, 8.0)**
- `aurora-mysql5-7-ssl-required`
- `aurora-mysql8-0-ssl-required`

**Note**: AWS Config does not have a managed rule to check RDS SSL enforcement. Instead, use these parameter groups when creating RDS instances to enforce SSL/TLS connections.

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

## How to Use RDS SSL/TLS Enforcement

After deploying this module, use the created parameter groups when creating RDS instances to enforce SSL/TLS:

### PostgreSQL Instance

```hcl
resource "aws_db_instance" "postgres" {
  identifier           = "my-postgres-db"
  engine              = "postgres"
  engine_version      = "16.1"
  instance_class      = "db.t3.micro"
  
  # Encryption at rest
  storage_encrypted   = true
  kms_key_id         = aws_kms_key.rds.arn
  
  # Encryption in transit (SSL/TLS) - Use version-specific parameter group
  parameter_group_name = "postgresql-postgres16-ssl-required"  # Match your engine version
  
  # Other settings...
}
```

### MySQL Instance

```hcl
resource "aws_db_instance" "mysql" {
  identifier           = "my-mysql-db"
  engine              = "mysql"
  engine_version      = "8.0.35"
  instance_class      = "db.t3.micro"
  
  # Encryption at rest
  storage_encrypted   = true
  kms_key_id         = aws_kms_key.rds.arn
  
  # Encryption in transit (SSL/TLS) - Use version-specific parameter group
  parameter_group_name = "mysql-mysql80-ssl-required"  # Match your engine version
  
  # Other settings...
}
```

### Aurora PostgreSQL Cluster

```hcl
resource "aws_rds_cluster" "aurora_postgres" {
  cluster_identifier   = "my-aurora-cluster"
  engine              = "aurora-postgresql"
  engine_version      = "16.1"
  
  # Encryption at rest
  storage_encrypted   = true
  kms_key_id         = aws_kms_key.rds.arn
  
  # Encryption in transit (SSL/TLS) - Use version-specific parameter group
  db_cluster_parameter_group_name = "aurora-postgresql16-ssl-required"  # Match your engine version
  
  # Other settings...
}
```

### Aurora MySQL Cluster

```hcl
resource "aws_rds_cluster" "aurora_mysql" {
  cluster_identifier   = "my-aurora-mysql-cluster"
  engine              = "aurora-mysql"
  engine_version      = "8.0.mysql_aurora.3.05.2"
  
  # Encryption at rest
  storage_encrypted   = true
  kms_key_id         = aws_kms_key.rds.arn
  
  # Encryption in transit (SSL/TLS) - Use version-specific parameter group
  db_cluster_parameter_group_name = "aurora-mysql8-0-ssl-required"  # Match your engine version
  
  # Other settings...
}
```

### Verify SSL Enforcement

After creating your RDS instance:

```bash
# PostgreSQL
psql -h your-endpoint.rds.amazonaws.com -U username -d database \
  -c "SHOW rds.force_ssl;"
# Expected: rds.force_ssl = on

# MySQL  
mysql -h your-endpoint.rds.amazonaws.com -u username -p \
  -e "SHOW VARIABLES LIKE 'require_secure_transport';"
# Expected: require_secure_transport = ON
```

## Prerequisites

- AWS Config must be enabled in your account/region
- For SCPs: AWS Organizations with Service Control Policies enabled
- IAM permissions to create Config rules and roles
- Management account access (for creating/attaching SCPs)

## ⚠️ Critical: Management Account Limitation

**SCPs do NOT apply to the management account (master account).** This is an AWS limitation, not a configuration issue.

### Why This Matters
- If you test from the management account, SCPs will NOT block operations
- You must test from a **member account** to validate SCP enforcement
- Management account: <YOUR-MGMT-ACCOUNT-ID> (bypasses all SCPs)
- Member accounts: Subject to SCP enforcement

### Testing SCPs Properly

1. **Create a member account** (or use existing member account)
2. **Attach SCPs** to the member account
3. **Assume a role** in the member account from management account
4. **Test operations** - SCPs will now be enforced

See [cross-account-role documentation](../../iam/cross-account-role/README.md) for setup instructions.

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
- `security_sns_topic_arn` - SNS topic ARN for security compliance alerts (EventBridge integration)
- `aws_region` - AWS region (default: `eu-north-1` Stockholm)
- `environment` - Environment name (default: `prod`)

## EventBridge Integration for Compliance Alerts

This module can send automatic email alerts when Config rules detect non-compliant resources.

### How It Works

1. **AWS Config** evaluates resources against compliance rules
2. **EventBridge** listens for compliance state changes to `NON_COMPLIANT`
3. **SNS** sends formatted email alerts to configured recipients

### Setup

1. Deploy SNS topic in `deployments/aws/management/sns-notifications/`
2. Configure `security_sns_topic_arn` variable with the SNS topic ARN
3. Confirm email subscription (check inbox for AWS SNS confirmation)

### Alert Format

```
🚨 AWS Config Compliance Violation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rule:          rds-require-ssl-connection
Status:        NON_COMPLIANT
Resource:      my-database-instance
Type:          AWS::RDS::DBInstance
Region:        eu-north-1
Account:       123456789012
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Action Required: Review and remediate the non-compliant resource.
```

See main [AWS README](../../README.md#security-compliance-alerting) for EventBridge explanation and RDS SSL configuration examples.

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
