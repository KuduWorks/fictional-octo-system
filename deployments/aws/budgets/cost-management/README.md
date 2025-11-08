# AWS Budget and Cost Management

This Terraform module creates AWS Budgets with automated alerting to help you monitor and control your AWS spending.

## What This Module Creates

- **AWS Budget**: Monthly budget tracking with configurable limits
- **SNS Topic**: For sending budget alert notifications
- **Email Subscriptions**: Automated email alerts when thresholds are reached
- **Multiple Alert Thresholds**:
  - 80% of budget (actual spend)
  - 100% of budget (actual spend)
  - 100% of budget (forecasted spend)
- **Optional Components**:
  - Quarterly budgets
  - Service-specific budgets (EC2, S3)
  - Tag-based budgets for cost tracking by project/team
  - CloudWatch billing alarm (additional layer)

## Features

### 🎯 Budget Types

1. **Monthly Budget**: Track total monthly AWS spending
2. **Quarterly Budget**: Long-term cost tracking (optional)
3. **Service Budgets**: Monitor specific services like EC2, S3 (optional)
4. **Tag-Based Budgets**: Track costs by projects, teams, or environments (optional)

### 🔔 Alert Mechanisms

- **AWS Budgets Notifications**: SNS-based alerts at configurable thresholds
- **Email Notifications**: Direct email alerts to multiple recipients
- **Forecasting**: Get alerts before you hit the limit based on spending trends
- **CloudWatch Alarms**: Additional billing monitoring layer (optional)

### 💰 Cost Tracking

The module helps you:
- Set spending limits per month/quarter
- Get early warnings at 80% spend
- Track forecasted costs to avoid surprises
- Monitor specific services or tags
- Stay within compliance/governance requirements

## Prerequisites

- AWS CLI configured with credentials
- Terraform >= 1.0
- AWS account with billing access
- Valid email addresses for alerts

## Quick Start

1. **Copy the example configuration:**
   ```bash
   cd deployments/aws/budgets/cost-management/
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit `terraform.tfvars` with your settings:**
   ```hcl
   environment = "prod"
   monthly_budget_limit = "100"
   alert_email_addresses = ["admin@example.com"]
   ```

3. **Deploy:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Confirm email subscriptions:**
   - Check your email inbox
   - Click the confirmation link from AWS SNS
   - Repeat for each email address configured

## Configuration Examples

### Basic Setup (Monthly Budget Only)

```hcl
environment           = "prod"
monthly_budget_limit  = "100"
alert_email_addresses = ["admin@example.com"]
```

### Advanced Setup (Multiple Budgets)

```hcl
environment = "prod"

# Total budgets
monthly_budget_limit    = "500"
enable_quarterly_budget = true
quarterly_budget_limit  = "1500"

# Service-specific budgets
enable_service_budgets = true
ec2_budget_limit      = "300"
s3_budget_limit       = "50"

# Multiple alert recipients
alert_email_addresses = [
  "admin@example.com",
  "finance@example.com",
  "cto@example.com"
]

# Custom alert thresholds
alert_threshold_actual_80       = 75   # Alert at 75% instead of 80%
alert_threshold_actual_100      = 100
alert_threshold_forecasted_100  = 90   # Early warning at 90% forecast
```

### Tag-Based Budgets (Project/Team Tracking)

```hcl
environment          = "prod"
monthly_budget_limit = "500"

# Track spending by project
tag_based_budgets = {
  "project-alpha" = {
    tag_key   = "Project"
    tag_value = "alpha"
    limit     = "200"
  }
  "team-frontend" = {
    tag_key   = "Team"
    tag_value = "frontend"
    limit     = "150"
  }
  "env-production" = {
    tag_key   = "Environment"
    tag_value = "prod"
    limit     = "400"
  }
}
```

## How Alerts Work

### Alert Thresholds

| Threshold | Type | When It Triggers |
|-----------|------|------------------|
| 80% | Actual | You've spent 80% of your budget |
| 100% | Actual | You've reached or exceeded your budget |
| 100% | Forecasted | AWS predicts you'll exceed budget by month end |

### Email Notification Flow

1. You set budget limit to $100
2. Your spending reaches $80 (80% threshold)
3. AWS Budgets detects threshold breach
4. SNS publishes message to topic
5. Email sent to all subscribed addresses
6. You receive alert and can take action

### Sample Alert Email

```
Subject: AWS Budget Alert: monthly-budget-prod

Your AWS budget "monthly-budget-prod" has exceeded 80% of the budget limit.

Budget Name: monthly-budget-prod
Budget Limit: $100.00
Current Spend: $82.45
Threshold: 80%
```

## Cost

### AWS Budgets Pricing

- **First 2 budgets**: Free
- **Additional budgets**: $0.02/day per budget (~$0.60/month)

### Example Costs

| Configuration | Monthly Cost |
|---------------|--------------|
| 1 monthly budget | $0.00 (free) |
| Monthly + Quarterly | $0.00 (free) |
| Monthly + Quarterly + 2 service budgets | ~$1.20 |
| Full setup (6 budgets) | ~$2.40 |

**Note**: SNS notifications are essentially free for email (first 1,000 notifications/month free)

## Viewing Your Budgets

### AWS Console

1. Navigate to: https://console.aws.amazon.com/billing/home#/budgets
2. You'll see all configured budgets
3. View current spend vs. budget
4. Check alert history

### CLI

```bash
# List all budgets
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)

# View specific budget
aws budgets describe-budget --account-id YOUR_ACCOUNT_ID --budget-name monthly-budget-prod
```

## Terraform Backend Configuration

To use remote state storage (recommended):

1. **Uncomment backend configuration in `main.tf`:**
   ```hcl
   backend "s3" {
     bucket         = "fictional-octo-system-tfstate-YOUR-ACCOUNT-ID"
     key            = "aws/budgets/cost-management/terraform.tfstate"
     region         = "eu-north-1"
     encrypt        = true
     dynamodb_table = "terraform-state-locks"
   }
   ```

2. **Replace `YOUR-ACCOUNT-ID`** with your AWS account ID

3. **Re-initialize:**
   ```bash
   terraform init
   ```

## Troubleshooting

### Email Subscription Not Confirmed

**Problem**: Not receiving emails after deployment

**Solution**:
1. Check spam/junk folder
2. Request new confirmation:
   ```bash
   aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)
   ```
3. If status is "PendingConfirmation", resend confirmation via AWS Console

### Budget Not Triggering Alerts

**Problem**: Spending exceeded threshold but no alert received

**Solution**:
1. Verify email subscription is confirmed (status: "Confirmed")
2. Check AWS Budgets console for alert history
3. Ensure billing data is up to date (can take 24 hours)
4. Verify SNS topic policy allows budgets.amazonaws.com to publish

### "Access Denied" When Creating Budget

**Problem**: Terraform fails with permissions error

**Solution**: Ensure your IAM user/role has these permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "budgets:*",
        "sns:*",
        "cloudwatch:PutMetricAlarm"
      ],
      "Resource": "*"
    }
  ]
}
```

### Budget Shows Different Currency

**Problem**: Budget is in wrong currency

**Solution**: AWS Budgets uses your account's default currency. To change:
1. Go to AWS Billing Console → Billing Preferences
2. Update currency settings
3. Recreate budgets with correct currency

## Best Practices

### 1. Start Conservative
- Begin with higher thresholds (e.g., $100/month)
- Adjust based on actual usage patterns
- Review costs monthly for first 3 months

### 2. Multiple Alert Tiers
```hcl
alert_threshold_actual_80       = 60   # Early warning
alert_threshold_actual_100      = 85   # Action required
alert_threshold_forecasted_100  = 100  # Prevent overspend
```

### 3. Use Service Budgets
Enable service-specific budgets to identify cost drivers:
- EC2 instances running 24/7
- S3 storage accumulation
- Data transfer costs

### 4. Tag-Based Tracking
Implement cost allocation tags:
```hcl
tag_based_budgets = {
  "project-*" = { ... }  # Per-project budgets
  "team-*" = { ... }     # Per-team budgets
  "env-*" = { ... }      # Per-environment budgets
}
```

### 5. Alert Multiple Stakeholders
```hcl
alert_email_addresses = [
  "admin@company.com",      # Technical owner
  "finance@company.com",    # Finance team
  "manager@company.com"     # Management
]
```

## Integration with Other Modules

This module complements:

- **Encryption Baseline** (`deployments/aws/policies/encryption-baseline/`): Ensure secure, compliant infrastructure
- **Region Control** (`deployments/aws/policies/region-control/`): Prevent unauthorized deployments
- **Resource Tagging**: Enable accurate cost allocation

## Comparison with Azure Cost Management

| Feature | Azure Cost Management | AWS Budgets |
|---------|----------------------|-------------|
| Budget Creation | Cost Management + Budgets | AWS Budgets |
| Alerting | Action Groups | SNS Topics |
| Cost Analysis | Cost Analysis blade | Cost Explorer |
| Tagging | Azure Tags | AWS Tags |
| Forecasting | Built-in | Built-in |
| Automation | Azure Automation | Lambda (custom) |
| API Access | Cost Management API | AWS Budgets API |

## Cleanup

To remove all budget resources:

```bash
terraform destroy
```

**Warning**: This will:
- Delete all budgets (you'll lose cost tracking history)
- Remove SNS topic and subscriptions
- Delete CloudWatch alarms (if enabled)

Budget alert history is not recoverable after deletion.

## Additional Resources

- [AWS Budgets Documentation](https://docs.aws.amazon.com/cost-management/latest/userguide/budgets-managing-costs.html)
- [AWS Budgets Pricing](https://aws.amazon.com/aws-cost-management/pricing/)
- [AWS Cost Explorer](https://aws.amazon.com/aws-cost-management/aws-cost-explorer/)
- [AWS Billing and Cost Management Best Practices](https://docs.aws.amazon.com/cost-management/latest/userguide/best-practices.html)

## Related Modules

- Azure Cost Management: `deployments/azure/policies/cost-management/`
- AWS Encryption Baseline: `deployments/aws/policies/encryption-baseline/`
- Terraform State Bootstrap: `deployments/aws/terraform-state-bootstrap/`

## Support

For issues or questions:
1. Check [Troubleshooting](#troubleshooting) section
2. Review AWS Budgets documentation
3. Open an issue in the repository
