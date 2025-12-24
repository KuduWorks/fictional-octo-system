# AWS SNS Notifications for Budget Alerting

This module creates SNS topics in us-east-1 for AWS Budgets alerting. Two separate topics are created: one for organization-wide budget alerts and one for member account workload budget alerts.

> **Note:** All email addresses used in this documentation are placeholders. Replace them with your actual email addresses when deploying.

## What This Creates

### SNS Topics
1. **org-budget-alerts** - Organization-wide budget notifications
   - Alerts when total AWS spending across all accounts approaches limits
   - Sent to finance/management email address
   - Monitors $100/month organization budget

2. **member-budget-alerts** - Member account workload notifications
   - Alerts when member account spending approaches threshold
   - Sent to DevOps/engineering team email address
   - Monitors $90/month member account budget

### Email Subscriptions
- Email protocol subscriptions for both topics
- **Requires manual confirmation** after deployment
- Confirmation emails sent by AWS to specified addresses

## Why us-east-1?

AWS Budgets service operates globally from us-east-1. SNS topics must be in the same region as the Budgets service for direct integration. This is an AWS service requirement, not a region control policy violation (Budgets and SNS are global/exempt services).

## Prerequisites

1. **Management Account Access** - Deploy from management account
2. **Valid Email Addresses** - Accessible for confirmation
3. **us-east-1 Region** - Module enforces this via validation

## Usage

### 1. Copy Example Files

```bash
cd deployments/aws/sns-notifications

# Copy terraform.tfvars example
cp terraform.tfvars.example terraform.tfvars

# Edit with your email addresses
# org_alert_email: for org-wide budget alerts (e.g., finance team)
# member_alert_email: for workload budget alerts (e.g., DevOps team)
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Changes

```bash
terraform plan
```

### 4. Deploy Topics

```bash
terraform apply
```

### 5. **IMPORTANT: Confirm Email Subscriptions**

After deployment, AWS sends confirmation emails to both addresses:

```
Subject: AWS Notification - Subscription Confirmation
From: no-reply@sns.amazonaws.com

You have chosen to subscribe to the topic:
arn:aws:sns:us-east-1:123456789012:org-budget-alerts

To confirm this subscription, click or visit the link below...
```

**You must click the confirmation link in each email** for alerts to work. Unconfirmed subscriptions will not receive notifications.

### 6. Verify Subscriptions

```bash
# Check organization budget alerts topic
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:org-budget-alerts \
  --region us-east-1

# Check member budget alerts topic
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:member-budget-alerts \
  --region us-east-1

# Look for "SubscriptionArn" that is not "PendingConfirmation"
```

### 7. Test Notifications (Optional)

```bash
# Get topic ARN from outputs
ORG_TOPIC_ARN=$(terraform output -raw org_budget_alerts_topic_arn)

# Send test message
aws sns publish \
  --topic-arn $ORG_TOPIC_ARN \
  --subject "Test Alert" \
  --message "This is a test notification from AWS SNS" \
  --region us-east-1

# Check your email for the test message
```

## Outputs

After deployment, use these outputs in budget configuration:

```hcl
# In budgets module, reference SNS topic ARNs
data "terraform_remote_state" "sns" {
  backend = "s3"
  config = {
    bucket = "<YOUR-STATE-BUCKET>"
    key    = "aws/sns-notifications/terraform.tfstate"
    region = "eu-north-1"
  }
}

resource "aws_budgets_budget" "organization" {
  # ...
  notification {
    comparison_operator = "GREATER_THAN"
    threshold           = 80
    threshold_type      = "PERCENTAGE"
    notification_type   = "ACTUAL"
    subscriber_sns_topic_arns = [
      data.terraform_remote_state.sns.outputs.org_budget_alerts_topic_arn
    ]
  }
}
```

## Important Notes

### 1. Email Confirmation Required
**Subscriptions will not work until confirmed.** AWS requires double opt-in for email subscriptions. Check spam folders if confirmation emails don't arrive within 5 minutes.

### 2. Confirmation Expiration
Confirmation links expire after 3 days. If expired, you can trigger a new confirmation:

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:org-budget-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region us-east-1
```

### 3. Region Locked to us-east-1
Module includes validation to prevent deployment in other regions. This is intentional for Budgets integration.

### 4. Multiple Subscribers
You can add more email addresses after deployment:

```bash
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:<YOUR-ACCOUNT-ID>:org-budget-alerts \
  --protocol email \
  --notification-endpoint additional-email@example.com \
  --region us-east-1
```

### 5. Email Delivery
SNS emails may be marked as spam. Add `no-reply@sns.amazonaws.com` to your email safe sender list.

## Cost

SNS pricing for this configuration:
- **Topics**: Free (no charge for topic creation)
- **Email notifications**: Free (no charge for email protocol)
- **Publishing**: First 1,000 publishes/month free, then $0.50 per million
- **Expected cost**: $0/month (budget alerts publish 1-5 times/month)

SNS is well within free tier for budget alerting use case.

## Backend Configuration

After deploying with local state, migrate to remote state:

```bash
# Copy backend example
cp backend.tf.example backend.tf

# Edit backend.tf with your state bucket name
# (Get bucket name from terraform-state-bootstrap outputs)

# Migrate state to S3
terraform init -migrate-state
```

## Troubleshooting

### Confirmation Email Not Received
1. Check spam/junk folders
2. Verify email address in terraform.tfvars
3. Check email provider isn't blocking AWS emails
4. Manually trigger new confirmation (see command above)

### "Subscription pending confirmation" After 24 Hours
The subscription was never confirmed. Check for confirmation email or manually subscribe again.

### Cannot Change Email Address
To change subscription email:
1. Add new subscription with new email
2. Confirm new subscription
3. Remove old subscription: `aws sns unsubscribe --subscription-arn <OLD-ARN>`

### Topics Not Visible in Console
Ensure you're viewing us-east-1 region in AWS Console. Topics in other regions won't appear.

### Budget Alerts Not Working
1. Verify subscriptions are confirmed (not pending)
2. Check budget notification configuration references correct topic ARN
3. Test with `aws sns publish` command to verify delivery
4. Check CloudTrail for SNS publish events

## Security Best Practices

1. ✅ **Use role-specific emails** (finance@, devops@) not personal addresses
2. ✅ **Limit subscription access** with SNS topic policies if needed
3. ✅ **Monitor subscription changes** via CloudTrail
4. ✅ **Use HTTPS endpoints** if adding webhook subscriptions later
5. ✅ **Review subscribers regularly** to remove former employees
6. ✅ **Enable CloudWatch Logs** for SNS delivery status if needed

## Related Modules

- [budget-monitoring](../budget-monitoring/) - Uses these SNS topics for budget alerting
- [finops-lambda](../finops-lambda/) - Alternative cost monitoring via Lambda

## Example Use Cases

### Organization Budget Alert Email
```
Subject: AWS Budget Alert - 80% of budget used
To: finance@example.com

Your organization has used 80% of the monthly budget.

Budget Name: Organization Monthly Budget
Limit: $100.00
Current Spend: $80.23
Forecasted: $95.50

Please review spending in AWS Cost Explorer.
```

### Member Account Alert Email
```
Subject: AWS Budget Alert - 50% of budget used
To: devops@example.com

Member account <YOUR-MEMBER-ACCOUNT-ID> has used 50% of monthly budget.

Budget Name: Member Account Workload Budget
Limit: $90.00
Current Spend: $45.67
Forecasted: $85.20

Please review resource usage and optimize if needed.
```

## Support

For issues or questions:
- Review [AWS SNS email notifications documentation](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)
- Check [AWS SNS troubleshooting guide](https://docs.aws.amazon.com/sns/latest/dg/sns-troubleshooting.html)
- Open an issue in the repository
