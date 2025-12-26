# AWS Budget Monitoring

Two-tier cost control and alerting for AWS Organization with multi-threshold notifications via SNS email alerts.

## Overview

This module creates **2 budgets**:
- **Organization-wide budget** ($100/month default) - tracks all accounts
- **Member account budget** ($90/month default) - tracks specific workload account

**Total Alerts**: 7 notifications (3 org + 4 member)  
**Cost**: $0.00/month (first 2 budgets free, SNS handled by separate module)

## Architecture

```
Management Account (us-east-1 - Budgets must be in this region)
│
├── Organization Budget ($100/month)
│   ├── 80% actual ($80) → org-budget-alerts SNS
│   ├── 100% actual ($100) → org-budget-alerts SNS
│   └── 100% forecast → org-budget-alerts SNS
│
└── Member Account Budget ($90/month)
    ├── 50% actual ($45) → member-budget-alerts SNS
    ├── 80% actual ($72) → member-budget-alerts SNS
    ├── 100% actual ($90) → member-budget-alerts SNS
    └── 100% forecast → member-budget-alerts SNS

SNS Topics (us-east-1, created by sns-notifications module)
├── org-budget-alerts → <YOUR-EMAIL-1>, <YOUR-EMAIL-2>
└── member-budget-alerts → <YOUR-EMAIL-1>, <YOUR-EMAIL-2>
```

## Features

✅ **Two-tier budget tracking** - Organization + member account specific  
✅ **7 alert thresholds** - Early warning (50%, 80%) + critical (100%) + forecasting  
✅ **SNS email integration** - Leverages existing sns-notifications module  
✅ **Zero cost** - First 2 budgets free, SNS already deployed  
✅ **Forecast alerts** - Predictive warnings before month-end overspend  
✅ **Flexible start dates** - Optional custom billing period  
✅ **Multi-account support** - Tracks organization-wide and specific accounts  

## Prerequisites

### 1. SNS Notifications Module Deployed (CRITICAL)

This module **requires** the `sns-notifications` module to be deployed first:

```bash
cd ../sns-notifications
terraform apply

# Get the SNS topic ARNs
terraform output org_sns_topic_arn
terraform output member_sns_topic_arn
```

**Expected output:**
```
org_sns_topic_arn = "arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:org-budget-alerts"
member_sns_topic_arn = "arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:member-budget-alerts"
```

### 2. Email Subscriptions Confirmed

**Before deploying budgets**, confirm SNS email subscriptions:

```bash
# Check subscription status
aws sns list-subscriptions --region us-east-1 --profile mgmt

# Look for "SubscriptionArn" (not "PendingConfirmation")
```

If pending:
1. Check email inbox (and spam folder)
2. Click "Confirm subscription" link from AWS
3. Verify confirmation in SNS console

**Without confirmation, NO budget alerts will be received!**

### 3. AWS Budgets Region Requirement

**CRITICAL**: AWS Budgets service **only works in us-east-1**.

```bash
# Verify region in terraform.tfvars
aws_region = "us-east-1"  # Must be us-east-1, not eu-north-1!
```

### 4. Terraform State Backend

Ensure `terraform-state-bootstrap` is deployed:
```bash
cd ../terraform-state-bootstrap
terraform apply
```

### 5. IAM Permissions

**Management Account:**
- `budgets:CreateBudget`
- `budgets:ModifyBudget`
- `budgets:ViewBudget`
- `budgets:DeleteBudget`
- `sns:Publish` (to send to SNS topics)

## Quick Start

### Step 1: Copy Configuration Files

```bash
cd deployments/aws/budget-monitoring

# Copy terraform.tfvars example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars
```

### Step 2: Configure Variables

Update `terraform.tfvars` with your SNS topic ARNs:

```hcl
# Get these ARNs from sns-notifications module outputs
org_sns_topic_arn    = "arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:org-budget-alerts"
member_sns_topic_arn = "arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:member-budget-alerts"

# Budget limits
org_budget_limit    = "100"  # $100/month for entire organization
member_budget_limit = "90"   # $90/month for member account workloads

# Member account to track
member_account_id = "<YOUR-MEMBER-ACCOUNT-ID>"  # 12-digit account ID

# Region and environment
aws_region  = "us-east-1"  # MUST be us-east-1 for AWS Budgets
environment = "prod"

# Optional: Custom start date (defaults to current month)
# budget_start_date = "2025-12-01"
```

### Step 3: Configure Backend (After State Bootstrap)

```bash
# Copy backend example
cp backend.tf.example backend.tf

# Edit with your state bucket
nano backend.tf
# bucket = "fictional-octo-system-tfstate-<YOUR-MGMT-ACCOUNT-ID>"
```

### Step 4: Deploy

```bash
# Set AWS credentials for management account
export AWS_PROFILE=mgmt

# Initialize Terraform
terraform init

# Review changes
terraform plan

# Deploy budgets
terraform apply
```

### Step 5: Verify Deployment

```bash
# List budgets
aws budgets describe-budgets \
  --account-id <YOUR-MGMT-ACCOUNT-ID> \
  --region us-east-1

# View organization budget
aws budgets describe-budget \
  --account-id <YOUR-MGMT-ACCOUNT-ID> \
  --budget-name organization-monthly-budget \
  --region us-east-1

# Check current spend
aws budgets describe-budget \
  --account-id <YOUR-MGMT-ACCOUNT-ID> \
  --budget-name organization-monthly-budget \
  --region us-east-1 \
  --query 'Budget.CalculatedSpend.ActualSpend'
```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `org_budget_limit` | Organization monthly budget (USD) | `"100"` | No |
| `member_budget_limit` | Member account monthly budget (USD) | `"90"` | No |
| `member_account_id` | Member account ID to track | - | Yes |
| `org_sns_topic_arn` | SNS topic ARN for org alerts | - | Yes |
| `member_sns_topic_arn` | SNS topic ARN for member alerts | - | Yes |
| `aws_region` | AWS region (must be us-east-1) | `"us-east-1"` | Yes |
| `environment` | Environment name | `"prod"` | No |
| `budget_start_date` | Budget period start (YYYY-MM-DD) | `""` | No |

### Budget Alert Thresholds

#### Organization Budget ($100/month)

Tracks spending across **all accounts** in organization.

| Threshold | Amount | Type | Action |
|-----------|--------|------|--------|
| 80% | $80 | Actual | ⚠️ Early warning - review spending |
| 100% | $100 | Actual | ��� Critical - immediate action required |
| 100% | $100 (est.) | Forecast | ��� Predictive - adjust plans before month-end |

#### Member Account Budget ($90/month)

Tracks spending **only for member account**.

| Threshold | Amount | Type | Action |
|-----------|--------|------|--------|
| 50% | $45 | Actual | ℹ️ Informational - mid-month checkpoint |
| 80% | $72 | Actual | ⚠️ Warning - review workload costs |
| 100% | $90 | Actual | ��� Critical - stop non-essential resources |
| 100% | $90 (est.) | Forecast | ��� Predictive - plan cost optimizations |

**Why more thresholds for member account?**  
The member account runs actual workloads (Lambda, containers, storage) and needs granular monitoring. The organization budget is higher-level governance.

## Troubleshooting

### Common Issues

#### 1. Error: "Budget must be created in us-east-1"

**Problem**: AWS Budgets service only available in us-east-1.

**Solution**:
```hcl
# Update terraform.tfvars
aws_region = "us-east-1"  # NOT eu-north-1!
```

Then re-initialize:
```bash
terraform init -reconfigure
terraform apply
```

**Root Cause**: AWS Budgets is a global service managed in us-east-1 region only.

---

#### 2. No email alerts received

**Problem**: SNS subscriptions not confirmed or SNS topics don't exist.

**Solution**:
```bash
# 1. Verify SNS topics exist
aws sns list-topics --region us-east-1 | grep budget-alerts

# 2. Check subscription status
aws sns list-subscriptions --region us-east-1

# 3. Look for "PendingConfirmation" - if found, check email
# 4. Confirm subscriptions via email links

# 5. Verify subscriptions are confirmed
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:org-budget-alerts \
  --region us-east-1
```

**Root Cause**: SNS requires explicit email confirmation. Check spam folder for confirmation emails from AWS.

---

#### 3. Error: "time_period_start cannot be parsed"

**Problem**: Invalid date format or empty string for `budget_start_date`.

**Solution**:
```hcl
# In terraform.tfvars, use YYYY-MM-DD format:
budget_start_date = "2025-12-01"

# Or leave it null to use current month:
budget_start_date = null

# Or comment it out entirely:
# budget_start_date = "2025-12-01"
```

**Root Cause**: AWS Budgets expects ISO 8601 date format with time component (`YYYY-MM-DD_HH:MM`), but Terraform adds the time automatically.

---

#### 4. Member account budget not created

**Problem**: `member_account_id` is empty or invalid.

**Solution**:
```bash
# Get your member account ID
aws organizations list-accounts

# Update terraform.tfvars
member_account_id = "<YOUR-MEMBER-ACCOUNT-ID>"  # Must be 12 digits

# Re-apply
terraform apply
```

**Root Cause**: The member budget uses conditional creation, so it's only created when account ID is provided.

---

#### 5. Budget shows zero spend despite running resources

**Problem**: AWS billing data has 24-hour lag.

**Solution**: Wait 24-48 hours after deploying resources. Budget calculations update once daily (usually around midnight UTC).

```bash
# Check Cost Explorer for more real-time data
aws ce get-cost-and-usage \
  --time-period Start=2025-12-01,End=2025-12-09 \
  --granularity DAILY \
  --metrics BlendedCost
```

**Root Cause**: AWS Budgets uses AWS Cost Explorer data, which updates daily, not in real-time.

---

### Validation Checklist

After deployment, verify:

- [ ] Both budgets visible in AWS Console (Billing → Budgets)
- [ ] SNS email subscriptions confirmed (check SubscriptionArn not "PendingConfirmation")
- [ ] Organization budget shows $100 limit
- [ ] Member account budget shows $90 limit and correct account filter
- [ ] Wait 24 hours for first spending data to appear
- [ ] Forecast data appears (may take 3-5 days after first billing data)
- [ ] Email alerts working (optional: create test resources to trigger 50% threshold)

## Cost Breakdown

| Component | Monthly Cost | Notes |
|-----------|--------------|-------|
| **AWS Budgets (first 2)** | $0.00 | Free tier |
| **SNS notifications** | $0.00 | Handled by sns-notifications module (~$0.50/month) |
| **Additional budgets** | $0.02/day (~$0.60/month) | Only if you add more than 2 budgets |
| **Total** | **$0.00/month** | This module is completely free |

**Savings**: By reusing SNS topics from `sns-notifications` module, we avoid duplicate SNS costs.

## Outputs

| Output | Description | Example Value |
|--------|-------------|---------------|
| `org_budget_name` | Organization budget name | `organization-monthly-budget` |
| `org_budget_id` | Organization budget ID | `budget-abc123def456` |
| `member_budget_name` | Member budget name | `member-account-monthly-budget` |
| `member_budget_id` | Member budget ID | `budget-ghi789jkl012` |
| `org_budget_limit` | Organization budget limit (USD) | `100` |
| `member_budget_limit` | Member budget limit (USD) | `90` |
| `member_account_id` | Member account being tracked | `<YOUR-MEMBER-ACCOUNT-ID>` |

## References

- [AWS Budgets Documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS Budgets Best Practices](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-best-practices.html)
- [AWS Budgets Pricing](https://aws.amazon.com/aws-cost-management/aws-budgets/pricing/)
- [SNS Email Notifications](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)

## Support

For issues or questions:

1. **Check troubleshooting section** above
2. **Review AWS Budgets Console** for detailed error messages
3. **Verify SNS subscriptions** are confirmed
4. **Review module dependencies** (sns-notifications, terraform-state-bootstrap)

---

**Related Documentation:**
- [AWS_DEPLOYMENT_GUIDE.md](../AWS_DEPLOYMENT_GUIDE.md) - Complete deployment guide for all modules
- [sns-notifications README](../sns-notifications/README.md) - SNS topic configuration
- [terraform-state-bootstrap README](../terraform-state-bootstrap/README.md) - State management setup

**Remember**: Set up budgets BEFORE deploying expensive infrastructure! 💰
