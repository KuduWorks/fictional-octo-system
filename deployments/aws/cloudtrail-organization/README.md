# AWS CloudTrail Organization Trail

This module creates an AWS CloudTrail organization trail with S3 storage in the management account. The trail captures all API activity across all accounts in your organization, storing logs in an encrypted S3 bucket with 30-day retention to balance security incident investigation capability with cost optimization.

> **Note:** All AWS account IDs used in this documentation (e.g., `<YOUR-MANAGEMENT-ACCOUNT-ID>`, `<YOUR-MEMBER-ACCOUNT-ID>`) are placeholders. Replace them with your actual AWS account IDs when deploying.

## What This Creates

### S3 Bucket for Log Storage
- **Name**: `fictional-octo-system-cloudtrail-<ACCOUNT-ID>`
- **Region**: eu-north-1 (matches primary region)
- **Encryption**: AES-256 server-side encryption
- **Versioning**: Enabled for recovery
- **Public Access**: Completely blocked
- **Lifecycle**: Automatic deletion after 30 days
- **Cost**: ~$1/month for 4 users

### CloudTrail Organization Trail
- **Multi-region**: Captures events from all AWS regions
- **Multi-account**: Logs from all organization accounts
- **Global services**: Includes IAM, CloudFront, Route53 events
- **Log validation**: File integrity verification enabled
- **Data events**: S3 object-level and Lambda function logging

### Access Control
- **CloudTrail service**: Write access to S3 bucket
- **Management account**: Full access via IAM
- **Member account SSO admins**: Read-only access to logs for debugging

## Why This Matters

CloudTrail provides:
- **Security audit**: Who did what, when, and from where
- **Compliance evidence**: Required for SOC 2, ISO 27001, PCI-DSS
- **Incident investigation**: Trace unauthorized access attempts
- **SCP validation**: See when SCPs block operations
- **Troubleshooting**: Debug API errors and permission issues

Without CloudTrail, you have no visibility into account activity or security incidents.

## Cost Breakdown

For a 4-user startup with serverless workloads:

| Component | Monthly Cost |
|-----------|-------------|
| CloudTrail trail (first trail free) | $0.00 |
| S3 storage (~200MB/month for 4 users) | ~$0.005 |
| S3 PUT requests (~10,000/month) | ~$0.05 |
| S3 GET requests (occasional) | ~$0.004 |
| **Total** | **~$0.06/month** |

With 30-day retention, logs are deleted before accumulating significant storage costs. Actual cost may reach ~$1-2/month depending on API call volume.

## Prerequisites

1. **AWS Organizations** - Organization trail requires organization setup
2. **Management Account Access** - Must deploy from management account
3. **S3 Bucket Permissions** - CloudTrail service needs write access

## Usage

### 1. Copy Example Files

```bash
cd deployments/aws/cloudtrail-organization

# Copy terraform.tfvars example
cp terraform.tfvars.example terraform.tfvars

# Edit with your member account ID
# member_account_id: account that should have read access to logs
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Changes

```bash
terraform plan
```

### 4. Deploy CloudTrail

```bash
terraform apply
```

### 5. Verify Deployment

```bash
# Check trail status
aws cloudtrail get-trail-status --name organization-trail

# Should show: "IsLogging": true

# List recent events (wait 5-10 minutes after deployment)
aws cloudtrail lookup-events --max-results 10

# Check S3 bucket exists
aws s3 ls s3://fictional-octo-system-cloudtrail-<YOUR-ACCOUNT-ID>/
```

### 6. Test Log Delivery

```bash
# Wait 15 minutes after deployment for first logs

# Check for log files in S3
aws s3 ls s3://fictional-octo-system-cloudtrail-<YOUR-ACCOUNT-ID>/AWSLogs/<YOUR-ORG-ID>/ --recursive

# Download a recent log file
aws s3 cp s3://fictional-octo-system-cloudtrail-<YOUR-ACCOUNT-ID>/AWSLogs/<YOUR-ORG-ID>/<ACCOUNT-ID>/CloudTrail/eu-north-1/2025/12/05/<LOG-FILE>.json.gz .

# Extract and view
gunzip <LOG-FILE>.json.gz
cat <LOG-FILE>.json | jq .
```

## Reading CloudTrail Logs from Member Account

Administrator SSO roles in the member account can read logs:

```bash
# From member account with AdministratorAccess SSO role

# List log files
aws s3 ls s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/<ORG-ID>/<MEMBER-ACCOUNT-ID>/CloudTrail/ --recursive

# Download specific log
aws s3 cp s3://fictional-octo-system-cloudtrail-<MGMT-ACCOUNT-ID>/AWSLogs/<ORG-ID>/<MEMBER-ACCOUNT-ID>/CloudTrail/eu-north-1/2025/12/05/<LOG-FILE>.json.gz .

# Read access is limited to administrator roles only
# Other roles will receive AccessDenied
```

## Understanding CloudTrail Events

### Example Event Structure

```json
{
  "eventVersion": "1.08",
  "userIdentity": {
    "type": "IAMUser",
    "principalId": "AIDAI...",
    "arn": "arn:aws:iam::123456789012:user/alice",
    "accountId": "123456789012",
    "userName": "alice"
  },
  "eventTime": "2025-12-05T10:30:15Z",
  "eventSource": "s3.amazonaws.com",
  "eventName": "CreateBucket",
  "awsRegion": "us-east-1",
  "sourceIPAddress": "203.0.113.42",
  "userAgent": "aws-cli/2.13.0",
  "errorCode": "AccessDenied",
  "errorMessage": "Service control policy restricts this action",
  "requestParameters": {
    "bucketName": "test-bucket"
  },
  "responseElements": null
}
```

### Key Fields
- **eventName**: What action was attempted (e.g., CreateBucket, RunInstances)
- **eventTime**: When it happened (UTC)
- **userIdentity**: Who made the request
- **sourceIPAddress**: Where the request came from
- **errorCode**: If action failed, why (AccessDenied, InvalidParameterValue)
- **awsRegion**: Which region was targeted

### Finding SCP Denials

```bash
# Search for SCP-blocked operations
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateBucket \
  --max-results 50 \
  --query 'Events[?contains(CloudTrailEvent, `AccessDenied`)]'

# Filter by user
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=alice \
  --max-results 50
```

## Important Notes

### 1. Log Delivery Delay
CloudTrail logs are delivered to S3 within **5-15 minutes** of API activity. Real-time monitoring requires CloudWatch Logs integration (not included, adds cost).

### 2. 30-Day Retention Trade-off
- **✅ Pros**: Low cost (~$1/month), adequate for incident response
- **❌ Cons**: Incidents discovered after 30 days lose audit trail
- **Recommendation**: For compliance requiring 1+ year retention, increase `log_retention_days` to 365 or 2555 (7 years)

### 3. Organization Trail Scope
This trail logs activity from **all accounts** in your organization. You cannot exclude specific accounts from an organization trail.

### 4. Data Events Cost
The configuration logs S3 object-level events and Lambda invocations. This adds to log volume but provides comprehensive visibility. For high-traffic S3 buckets, consider filtering specific buckets:

```hcl
# In main.tf, modify data_resource to filter
data_resource {
  type = "AWS::S3::Object"
  values = ["arn:aws:s3:::my-important-bucket/*"]  # Specific bucket only
}
```

### 5. Management Account Logs
Both organization logs (from all accounts) and management account logs are stored in the bucket under different paths:
- Organization: `s3://.../AWSLogs/<ORG-ID>/<ACCOUNT-ID>/...`
- Management: `s3://.../AWSLogs/<MGMT-ACCOUNT-ID>/...`

## Compliance Mapping

| Framework | Control | How CloudTrail Helps |
|-----------|---------|---------------------|
| **ISO 27001** | A.12.4.1 - Event logging | Records all AWS API activity |
| **SOC 2** | CC7.2 - System monitoring | Provides audit trail for changes |
| **PCI-DSS** | 10.2 - Audit logs | Tracks access to cardholder data environments |
| **NIST 800-53** | AU-2 - Audit events | Captures security-relevant events |
| **GDPR** | Article 30 - Records of processing | Documents data access and modifications |

## Backend Configuration

After deploying with local state, migrate to remote state:

```bash
# Copy backend example
cp backend.tf.example backend.tf

# Edit backend.tf with your state bucket name

# Migrate state to S3
terraform init -migrate-state
```

## Troubleshooting

### Trail Not Logging
```bash
# Check trail status
aws cloudtrail get-trail-status --name organization-trail

# If IsLogging: false, start it
aws cloudtrail start-logging --name organization-trail
```

### No Log Files in S3
- Wait 15 minutes after deployment
- Verify trail is logging (see above)
- Check CloudTrail service has write permissions to bucket
- Review bucket policy allows CloudTrail service principal

### "Insufficient permissions" When Accessing Logs from Member Account
- Verify you're using AdministratorAccess SSO role
- Check IAM role matches pattern: `AWSReservedSSO_AdministratorAccess_*`
- Confirm member_account_id in terraform.tfvars is correct

### High S3 Costs
- Check log volume: `aws s3 ls s3://your-bucket/AWSLogs/ --recursive --summarize`
- If unexpectedly high, disable data events for S3 objects
- Consider filtering to specific high-value buckets only

### Cannot Read Log Files
CloudTrail logs are gzip compressed JSON. Extract first:
```bash
gunzip <filename>.json.gz
cat <filename>.json | jq .
```

### Trail Deleted Accidentally
Terraform can recreate:
```bash
terraform apply
# CloudTrail service will resume logging
# Historical logs (if within 30 days) remain in S3
```

## Querying Logs with CloudWatch Insights

For advanced querying, integrate CloudTrail with CloudWatch Logs (additional cost):

```hcl
# Add to main.tf
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/organization"
  retention_in_days = 30
}

resource "aws_cloudtrail" "organization" {
  # ... existing config ...
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_cloudwatch.arn
}
```

**Cost impact**: ~$0.50/GB ingested + $0.03/GB stored. For 4 users, ~$5-10/month additional.

## Security Best Practices

1. ✅ **Enable log file validation** (included - detects tampering)
2. ✅ **Use organization trail** (captures all accounts)
3. ✅ **Encrypt logs** (AES-256 included)
4. ✅ **Block public access** (configured)
5. ✅ **Limit access** (only CloudTrail service and admins)
6. ✅ **Monitor trail changes** (CloudTrail logs its own modifications)
7. ✅ **Regular review** (automate with CloudWatch Alarms or Lambda)

## Advanced: Alerting on Specific Events

Create CloudWatch Event rule for critical events:

```hcl
resource "aws_cloudwatch_event_rule" "root_login" {
  name        = "detect-root-login"
  description = "Alert on AWS root account login"

  event_pattern = jsonencode({
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      userIdentity = {
        type = ["Root"]
      }
      eventName = ["ConsoleLogin"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.root_login.name
  target_id = "SendToSNS"
  arn       = var.alert_sns_topic_arn
}
```

## Related Modules

- [organization-protection](../policies/organization-protection/) - Restrict organization modifications
- [encryption-baseline](../policies/encryption-baseline/) - S3 encryption and public access SCPs
- [budget-monitoring](../budget-monitoring/) - Monitor CloudTrail costs

## Support

For issues or questions:
- Review [AWS CloudTrail documentation](https://docs.aws.amazon.com/cloudtrail/)
- Check [CloudTrail troubleshooting guide](https://docs.aws.amazon.com/cloudtrail/latest/userguide/cloudtrail-troubleshooting.html)
- Query logs: [Athena integration guide](https://docs.aws.amazon.com/athena/latest/ug/cloudtrail-logs.html)
- Open an issue in the repository
