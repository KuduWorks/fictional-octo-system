# AWS CloudTrail Organization Trail

Centralized audit logging for AWS Organization with 30-day retention, multi-account support, and administrator read access from member accounts.

## Overview

This module creates:
- **S3 Bucket** in management account (eu-north-1) for CloudTrail logs
- **Organization Trail** capturing API calls from all accounts
- **30-day retention** lifecycle policy (cost-optimized)
- **AES-256 encryption** for logs at rest
- **Versioning enabled** for log recovery
- **SSO Administrator read access** from member account

**Cost**: ~$0.50-1.00/month (depends on API call volume)

## Architecture

```
Management Account
└── S3 Bucket (CloudTrail logs)
    ├── AWSLogs/<ORG-ID>/ (organization logs)
    ├── AWSLogs/<MGMT-ACCOUNT-ID>/ (management account logs)
    └── Lifecycle: Delete after 30 days
    
Organization Trail
├── Captures: All API calls (management events)
├── Optional: S3 object-level events
├── Optional: Lambda invocation events
└── Writes to: Management account S3 bucket

Member Account
└── SSO AdministratorAccess role
    └── Read access to CloudTrail logs
```

## Features

✅ **Organization-wide logging** - Captures activity from all current and future member accounts  
✅ **Multi-region trail** - Logs events from all AWS regions  
✅ **Log file validation** - Cryptographic verification of log integrity  
✅ **Cost-optimized retention** - 30-day automatic deletion  
✅ **Secure access** - Only SSO administrators from member account can read logs  
✅ **Management events** - All AWS API calls logged by default  
⚠️ **Data events disabled by default** - S3 object-level and Lambda invocation logging commented out (see below)

## Prerequisites

### 1. AWS Organizations Setup

**Required:**
- AWS Organization created
- Management account access
- At least one member account

**Verification:**
```bash
aws organizations describe-organization
```

### 2. CloudTrail Service Access (CRITICAL)

**Before first deployment**, you must enable CloudTrail trusted access in your organization:

```bash
# Enable CloudTrail service access
aws organizations enable-aws-service-access \
  --service-principal cloudtrail.amazonaws.com

# Verify it's enabled
aws organizations list-aws-service-access-for-organization | grep cloudtrail
```

**Without this step, Terraform will fail with:**
```
Error: creating CloudTrail Trail: organizations exception: AWSOrganizationsNotInUseException
```

**Alternative (AWS Console):**
1. Sign in to management account
2. Navigate to: **AWS Organizations** → **Services**
3. Find **AWS CloudTrail** in the list
4. Click **Enable trusted access**

### 3. Terraform Backend

Ensure `terraform-state-bootstrap` is deployed first:
```bash
cd ../terraform-state-bootstrap
terraform apply
```

### 4. IAM Permissions

**Management Account:**
- `cloudtrail:CreateTrail`
- `cloudtrail:UpdateTrail`
- `s3:CreateBucket`
- `s3:PutBucketPolicy`
- `organizations:DescribeOrganization`

## Usage

### 1. Copy Example Files

```bash
cd deployments/aws/cloudtrail-organization

# Copy terraform.tfvars example
cp terraform.tfvars.example terraform.tfvars

# Edit with your member account ID
nano terraform.tfvars
# member_account_id = "<YOUR-MEMBER-ACCOUNT-ID>"
```

### 2. Configure Backend (After State Bootstrap)

```bash
# Copy backend example
cp backend.tf.example backend.tf

# Edit with your state bucket name
nano backend.tf
# bucket = "fictional-octo-system-tfstate-<YOUR-MGMT-ACCOUNT-ID>"
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review changes
terraform plan

# Deploy CloudTrail
terraform apply
```

### 4. Verify Deployment

```bash
# Check trail status
aws cloudtrail get-trail-status \
  --name organization-trail \
  --region eu-north-1

# Verify S3 bucket
aws s3 ls s3://fictional-octo-system-cloudtrail-<YOUR-MGMT-ACCOUNT-ID>/

# Wait 15 minutes for first logs, then check
aws s3 ls s3://fictional-octo-system-cloudtrail-<YOUR-MGMT-ACCOUNT-ID>/AWSLogs/ --recursive
```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `member_account_id` | Member account ID for read access | - | Yes |
| `organization_id` | AWS Organization ID | (auto-detected) | No |
| `aws_region` | AWS region for resources | `eu-north-1` | No |
| `environment` | Environment name | `prod` | No |
| `log_retention_days` | Days to retain logs | `30` | No |

### Example terraform.tfvars

```hcl
member_account_id  = "758027491266"
aws_region         = "eu-north-1"
environment        = "prod"
log_retention_days = 30
```

## Data Events (Optional)

By default, only **management events** (API calls) are logged. This keeps costs minimal (~$0.50-1/month).

### Enabling S3 Object-Level Logging

**Cost Impact**: Can add $1-5/month depending on S3 activity.

Uncomment in `main.tf`:
```hcl
event_selector {
  include_management_events = true
  read_write_type           = "All"

  data_resource {
    type   = "AWS::S3::Object"
    values = []  # All S3 objects across all buckets
  }
}
```

### Enabling Lambda Invocation Logging

**Cost Impact**: Can add $0.50-2/month depending on Lambda usage.

Uncomment in `main.tf`:
```hcl
event_selector {
  include_management_events = true
  read_write_type           = "All"

  data_resource {
    type   = "AWS::Lambda::Function"
    values = []  # All Lambda functions
  }
}
```

**Note**: Empty arrays `[]` log all resources. To log specific buckets/functions, provide explicit ARNs:
```hcl
values = ["arn:aws:s3:::my-specific-bucket/"]
```

## Accessing Logs

### From Management Account

```bash
# List logs
aws s3 ls s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/ --recursive

# Download log file
aws s3 cp s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/<ORG-ID>/CloudTrail/eu-north-1/2025/12/07/<LOG-FILE>.json.gz .

# Extract and view
gunzip <LOG-FILE>.json.gz
cat <LOG-FILE>.json | jq .
```

### From Member Account (SSO Administrator)

```bash
# Assume SSO Administrator role via Identity Center
# Then list logs
aws s3 ls s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/ --recursive

# Read-only access - cannot delete or modify logs
```

## Cost Breakdown

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| **CloudTrail Trail** | $0.00 | First trail in region is free |
| **S3 Storage** | ~$0.50 | ~20 GB logs/month for 4 users |
| **S3 Requests** | ~$0.10 | PUT requests from CloudTrail |
| **Data Events (optional)** | $1-5 | If S3/Lambda logging enabled |
| **Total** | **~$0.60-6/month** | Without/with data events |

**30-day retention saves ~$20/year** compared to 1-year retention for same usage.

## Security Considerations

✅ **Immutable logs** - Only CloudTrail service can write, prevents tampering  
✅ **Encrypted at rest** - AES-256 encryption on S3  
✅ **Versioning enabled** - Protects against accidental deletion  
✅ **Limited read access** - Only SSO administrators from member account  
✅ **Log validation** - Cryptographic proof logs haven't been modified  
✅ **Multi-region** - Captures events from all regions  

⚠️ **Management account administrators** have full access to logs (expected for governance)  
⚠️ **30-day retention** means older logs are automatically deleted (balance cost vs. compliance)

## Troubleshooting

### Common Issues

#### 1. Error: "AWSOrganizationsNotInUseException"

**Problem**: CloudTrail service access not enabled in organization.

**Solution**:
```bash
# Enable CloudTrail trusted access
aws organizations enable-aws-service-access \
  --service-principal cloudtrail.amazonaws.com

# Verify
aws organizations list-aws-service-access-for-organization
```

**Root Cause**: Organization trails require explicit service access permission. This is a one-time setup per organization.

---

#### 2. Error: "InvalidParameterValueException: Member must have value"

**Problem**: Data event selectors require either empty array `[]` or specific ARNs.

**Solution**: Use empty arrays for wildcard logging:
```hcl
data_resource {
  type   = "AWS::S3::Object"
  values = []  # NOT values = ["arn:aws:s3:::*/*"]
}

data_resource {
  type   = "AWS::Lambda::Function"
  values = []  # NOT values = ["arn:aws:lambda:*:*:function/*"]
}
```

**Root Cause**: CloudTrail API doesn't accept wildcard patterns like `*/*` in ARNs. Use empty array for "all resources" or provide specific ARNs.

---

#### 3. Error: "AccessDenied" when creating trail

**Problem**: Insufficient IAM permissions or bucket policy conflict.

**Solution**:
```bash
# Verify you're using management account credentials
aws sts get-caller-identity

# Check if you have CloudTrail permissions
aws iam simulate-principal-policy \
  --policy-source-arn $(aws sts get-caller-identity --query Arn --output text) \
  --action-names cloudtrail:CreateTrail \
  --resource-arns "*"
```

**Root Cause**: Organization trails must be created from management account with appropriate IAM permissions.

---

#### 4. No logs appearing in S3 bucket

**Problem**: Trail created but no logs written (can take 15-30 minutes for first logs).

**Solution**:
```bash
# Check trail is logging
aws cloudtrail get-trail-status --name organization-trail --region eu-north-1

# Verify IsLogging = true
# If false, start logging:
aws cloudtrail start-logging --name organization-trail --region eu-north-1

# Generate test activity
aws s3 ls  # Any AWS API call will be logged

# Check again after 5-10 minutes
aws s3 ls s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/ --recursive
```

**Root Cause**: CloudTrail batches logs and delivers them every 5-15 minutes. First delivery can take up to 30 minutes.

---

#### 5. Member account can't read logs

**Problem**: SSO administrator from member account gets AccessDenied when listing logs.

**Solution**:
```bash
# Verify bucket policy includes member account
aws s3api get-bucket-policy \
  --bucket fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID> \
  --query Policy --output text | jq .

# Check for AllowSSOAdminRead statement with your member_account_id

# If missing, re-apply Terraform with correct member_account_id variable
cd deployments/aws/cloudtrail-organization
terraform apply -var="member_account_id=758027491266"
```

**Root Cause**: Bucket policy references incorrect member account ID or SSO role pattern doesn't match actual role ARN.

---

#### 6. Lifecycle rule not deleting old logs

**Problem**: Logs older than 30 days still present in bucket.

**Solution**:
```bash
# Verify lifecycle configuration
aws s3api get-bucket-lifecycle-configuration \
  --bucket fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>

# Check expiration rule exists with 30 days
# Note: S3 lifecycle runs once per day (midnight UTC), not immediately

# Manually delete old logs if needed
aws s3 rm s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/ \
  --recursive \
  --exclude "*" \
  --include "*/2025/10/*"  # Delete October 2025 logs
```

**Root Cause**: S3 lifecycle policies run daily and may take 24-48 hours to delete objects after they become eligible.

---

#### 7. High CloudTrail costs

**Problem**: Monthly CloudTrail bill higher than expected (~$10+ instead of ~$1).

**Solution**:
```bash
# Check if data events are enabled
aws cloudtrail get-event-selectors --trail-name organization-trail --region eu-north-1

# If you see S3 or Lambda data resources, disable them:
# Edit main.tf and remove/comment data_resource blocks
terraform apply

# Or use AWS Console: CloudTrail → Trails → organization-trail → Event selectors
```

**Root Cause**: S3 object-level and Lambda invocation logging can generate millions of events/month. Disable if not needed for compliance.

---

### Validation Checklist

After deployment, verify:

- [ ] Trail status shows `IsLogging: true`
- [ ] S3 bucket has logs in `AWSLogs/<ORG-ID>/` path (wait 15-30 min)
- [ ] Member account SSO admin can list logs
- [ ] Lifecycle rule configured (30 days)
- [ ] Log file validation enabled
- [ ] Multi-region trail enabled
- [ ] No errors in CloudTrail console

## Outputs

| Output | Description |
|--------|-------------|
| `cloudtrail_bucket_name` | S3 bucket name for logs |
| `cloudtrail_bucket_arn` | S3 bucket ARN |
| `cloudtrail_arn` | Organization trail ARN |
| `cloudtrail_name` | Trail name |

## Rollback

To remove CloudTrail infrastructure:

```bash
# Destroy Terraform resources
terraform destroy

# Manually empty S3 bucket first if needed (Terraform may fail with non-empty bucket)
aws s3 rm s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/ --recursive

# Then retry destroy
terraform destroy
```

**Warning**: Deleting the trail stops audit logging organization-wide. Ensure you have log exports or backups if needed for compliance.

## References

- [AWS CloudTrail Organization Trails](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/creating-trail-organization.html)
- [CloudTrail Event Selectors](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/logging-data-events-with-cloudtrail.html)
- [CloudTrail Log File Validation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-log-file-validation-intro.html)
- [S3 Lifecycle Policies](https://docs.aws.amazon.com/AmazonS3/latest/userguide/object-lifecycle-mgmt.html)
