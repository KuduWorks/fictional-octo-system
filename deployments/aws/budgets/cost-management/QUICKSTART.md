# AWS Budget Quick Start Guide

Get your AWS budget and alerting set up in 5 minutes! 🚀

## What You'll Get

- Monthly budget tracking
- Email alerts at 80% and 100% spend
- Forecasting to prevent budget overruns
- Dashboard to visualize spending

## Prerequisites

✅ AWS CLI configured with credentials
✅ Email address for alerts
✅ 5 minutes of your time

## Step 1: Test Your AWS Credentials

```bash
aws sts get-caller-identity
```

You should see your AWS account ID, user ARN, and user ID.

## Step 2: Configure Your Budget

```bash
cd deployments/aws/budgets/cost-management/

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
nano terraform.tfvars  # or use your preferred editor
```

**Minimum required settings:**

```hcl
environment = "prod"
monthly_budget_limit = "100"  # Set your monthly limit in USD
alert_email_addresses = [
  "your.email@example.com"    # ⚠️ CHANGE THIS!
]
```

## Step 3: Deploy

```bash
# Initialize Terraform
terraform init

# Preview what will be created
terraform plan

# Create the budget
terraform apply
```

Type `yes` when prompted.

## Step 4: Confirm Email Subscription

**IMPORTANT**: You must confirm your email subscription!

1. Check your email inbox (and spam folder)
2. Look for email from AWS Notifications
3. Subject: "AWS Notification - Subscription Confirmation"
4. Click the **"Confirm subscription"** link

**Without confirmation, you won't receive alerts!**

## Step 5: View Your Budget Dashboard

Open this URL in your browser:
```
https://console.aws.amazon.com/billing/home#/budgets
```

You should see:
- `monthly-budget-prod` (or your environment name)
- Current spend: $0.00 (or your current month's spend)
- Budget limit: $100.00 (or your configured limit)

## What Gets Created

| Resource | Purpose | Cost |
|----------|---------|------|
| AWS Budget | Monthly spending limit | **Free** (first 2 budgets) |
| SNS Topic | Alert delivery | **~$0.00** (1,000 emails/month free) |
| Email Subscription | Receive alerts | **Free** |

**Total cost: $0.00** for basic setup! 🎉

## Testing Your Budget (Optional)

Want to test if alerts work? Launch a small EC2 instance:

```bash
# Launch a t2.micro instance (free tier eligible)
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t2.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=budget-test}]'
```

**Important**: Terminate it after testing to avoid charges!

```bash
# List instances
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key==`Name`].Value|[0]]' --output table

# Terminate test instance
aws ec2 terminate-instances --instance-ids i-YOUR-INSTANCE-ID
```

## Alert Examples

### 80% Alert (Early Warning)
```
AWS Budget Alert: monthly-budget-prod

Your budget has exceeded 80% of the limit.

Budget Name: monthly-budget-prod
Budget Limit: $100.00
Current Spend: $82.45
Threshold: 80% (Actual)
```

### 100% Alert (Limit Reached)
```
AWS Budget Alert: monthly-budget-prod

Your budget has exceeded 100% of the limit.

Budget Name: monthly-budget-prod
Budget Limit: $100.00
Current Spend: $103.67
Threshold: 100% (Actual)
```

### Forecasted Alert (Prediction)
```
AWS Budget Alert: monthly-budget-prod

Your forecasted spend is expected to exceed your budget.

Budget Name: monthly-budget-prod
Budget Limit: $100.00
Forecasted Spend: $115.23
Current Spend: $67.89
Days Remaining: 8
```

## Customization Options

### Multiple Email Recipients

```hcl
alert_email_addresses = [
  "admin@example.com",
  "finance@example.com",
  "cto@example.com"
]
```

### Quarterly Budget

```hcl
enable_quarterly_budget = true
quarterly_budget_limit = "300"
```

### Service-Specific Budgets

```hcl
enable_service_budgets = true
ec2_budget_limit = "50"   # Track EC2 costs separately
s3_budget_limit = "20"    # Track S3 costs separately
```

### Custom Alert Thresholds

```hcl
alert_threshold_actual_80 = 60        # Alert earlier at 60%
alert_threshold_actual_100 = 85       # Alert at 85%
alert_threshold_forecasted_100 = 90   # Forecast alert at 90%
```

## Troubleshooting

### Not Receiving Emails?

**Check 1**: Email subscription confirmed?
```bash
aws sns list-subscriptions-by-topic --topic-arn $(terraform output -raw sns_topic_arn)
```

Look for `"SubscriptionArn": "Pending"` → You need to confirm!

**Check 2**: Spam folder?
- AWS emails might be filtered
- Add `no-reply@sns.amazonaws.com` to contacts

**Check 3**: Correct email address?
- Verify `terraform.tfvars` has correct email
- Run `terraform apply` again if you changed it

### Budget Not Showing in Console?

**Check 1**: Correct AWS account?
```bash
aws sts get-caller-identity
```

**Check 2**: Correct region?
AWS Budgets are in US East (N. Virginia) but apply globally. View them here:
```
https://console.aws.amazon.com/billing/home?region=us-east-1#/budgets
```

### "Access Denied" Error?

Your IAM user needs these permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "budgets:*",
        "sns:*"
      ],
      "Resource": "*"
    }
  ]
}
```

## Next Steps

Once your budget is working:

1. **Review monthly**: Check spending trends in Cost Explorer
2. **Adjust limits**: Update `monthly_budget_limit` as needed
3. **Add service budgets**: Track EC2, S3, RDS separately
4. **Tag-based budgets**: Monitor costs by project/team
5. **Cost optimization**: Use AWS Trusted Advisor recommendations

## Cost Explorer

View detailed spending breakdown:
```
https://console.aws.amazon.com/cost-management/home#/cost-explorer
```

Features:
- Daily/monthly cost trends
- Service-level breakdown
- Resource-level costs
- Forecasting

## Cleanup

To remove the budget (not recommended unless testing):

```bash
cd deployments/aws/budgets/cost-management/
terraform destroy
```

Type `yes` when prompted.

**Warning**: This deletes all budget tracking. History cannot be recovered!

## Integration with Terraform State

Using the state backend from `terraform-state-bootstrap`? Update `main.tf`:

```hcl
backend "s3" {
  bucket         = "fictional-octo-system-tfstate-YOUR-ACCOUNT-ID"
  key            = "aws/budgets/cost-management/terraform.tfstate"
  region         = "eu-north-1"
  encrypt        = true
  dynamodb_table = "terraform-state-locks"
}
```

Then:
```bash
terraform init
```

## Comparison with Azure Cost Management

| Feature | Azure | AWS |
|---------|-------|-----|
| Budget Creation | Azure Portal / ARM | AWS Budgets / Terraform |
| Alert Mechanism | Action Groups | SNS Topics |
| Cost Dashboard | Cost Analysis | Cost Explorer |
| Alert Config | Azure Monitor | AWS Budgets Notifications |
| Deployment Tool | ARM Template | Terraform |

## Additional Resources

- **AWS Budgets Console**: https://console.aws.amazon.com/billing/home#/budgets
- **Cost Explorer**: https://console.aws.amazon.com/cost-management/home#/cost-explorer
- **Billing Dashboard**: https://console.aws.amazon.com/billing/home
- **Full Documentation**: `README.md` in this directory

## Getting Help

1. Check the [README.md](README.md) for detailed documentation
2. Review [Troubleshooting](#troubleshooting) section above
3. AWS Budgets documentation: https://docs.aws.amazon.com/cost-management/
4. Open an issue in the repository

---

**Pro Tip**: Set up budgets BEFORE deploying infrastructure to avoid surprise bills! 💰
