# GCP Budget Management

> *"Because nobody likes surprise cloud bills"* 💰🚨

This module manages Google Cloud billing budgets and cost alerts to prevent surprise charges and monitor spending.

## Features

- ✅ **Single Monthly Budget**: Overall billing account spending limit with multi-threshold alerts
- ✅ **All Services Monitoring**: Tracks all GCP services in one unified budget
- ✅ **Email Alerts**: Notifications at 50%, 75%, 90%, 100% thresholds
- ✅ **Forecast Alerts**: Predict when budget will be exceeded based on trends
- ✅ **EUR Currency**: Configured for European billing accounts
- ✅ **Easy Management**: Single budget simplifies cost tracking

## Quick Start

### Step 1: Get Your Billing Account ID

```bash
# List your billing accounts
gcloud billing accounts list

# Output will show:
# ACCOUNT_ID            NAME                OPEN  MASTER_ACCOUNT_ID
# 012345-6789AB-CDEFGH  My Billing Account  True
```

### Step 2: Configure Budget Settings

```bash
cd deployments/gcp/cost-management/budgets/

# Copy configuration template
cp terraform.tfvars.example terraform.tfvars

# Edit with your settings
nano terraform.tfvars
```

Update `terraform.tfvars`:
```hcl
billing_account_id = "012345-6789AB-CDEFGH"  # From step 1
monthly_budget_amount = 50                    # EUR per month
budget_alert_emails = [
  "your.email@domain.com"
]
```

### Step 3: Configure Backend

```bash
# Copy backend configuration
cp backend.tf.example backend.tf

# Update with your project ID
sed -i 's/<YOUR-PROJECT-ID>/<YOUR-PROJECT-ID>/g' backend.tf
```

### Step 4: Deploy Budgets

```bash
# Initialize Terraform
terraform init

# Review what will be created
terraform plan

# Deploy budgets
terraform apply
```

## What Gets Created

| Budget | Amount | Alerts | Purpose |
|--------|--------|--------|---------|
| **Monthly Budget** | Your specified limit | 50%, 75%, 90%, 100%, Forecast | All services across entire billing account |

## Alert Thresholds Explained

### Budget Alerts
- **50%** - Early warning, time to review spending
- **75%** - Check if projections are on track
- **90%** - High alert, consider cost optimization
- **100%** - Budget exceeded, immediate action needed
- **100% Forecast** - Predicted to exceed budget this month

## Budget Configuration Example

For a €50 monthly budget:
```
Total Budget:   €50/month
├─ Applies to:  All GCP services
├─ Scope:       Entire billing account
└─ Alerts:      50%, 75%, 90%, 100%, 100% forecast
```

## Viewing Budgets

### Web Console
```
https://console.cloud.google.com/billing/budgets?project=<YOUR-PROJECT-ID>
```

### CLI
```bash
# List all budgets
gcloud billing budgets list \
  --billing-account=YOUR-BILLING-ACCOUNT-ID

# Get budget details
gcloud billing budgets describe BUDGET-ID \
  --billing-account=YOUR-BILLING-ACCOUNT-ID
```

### Terraform
```bash
# View budget summary
terraform output budget_summary

# View setup instructions
terraform output setup_instructions
```

## Modifying Budgets

### Change Monthly Limit
```hcl
# In terraform.tfvars
monthly_budget_amount = 200  # Increase to €200/month
```

### Add More Email Recipients
```hcl
# In terraform.tfvars
budget_alert_emails = [
  "devops@domain.com",
  "finance@domain.com",
  "manager@domain.com"
]
```

### Adjust Alert Thresholds
Edit `main.tf` to customize alert percentages:
```terraform
# Add or modify threshold rules
threshold_rules {
  threshold_percent = 0.6   # Alert at 60%
  spend_basis       = "CURRENT_SPEND"
}
```

## Cost Optimization Tips

1. **Set Realistic Budgets**: Start low, adjust based on actual usage
2. **Monitor Regularly**: Check alerts weekly, don't ignore them
3. **Use Service Budgets**: Identify which services cost the most
4. **Enable Recommendations**: GCP provides cost optimization suggestions
5. **Review Unused Resources**: Delete idle VMs, old snapshots, unused storage

## Troubleshooting

### "Permission denied" error
```bash
# Ensure you have billing admin permissions
gcloud projects add-iam-policy-binding <YOUR-PROJECT-ID> \
  --member="user:YOUR-EMAIL@domain.com" \
  --role="roles/billing.admin"
```

### Email notifications not received
1. Check email addresses in terraform.tfvars
2. Verify notification channels: `terraform output notification_channels`
3. Check spam folder
4. Confirm billing account is active

### Budget not triggering alerts
- Budgets need actual spend data to trigger
- Wait 24-48 hours for billing data to populate
- Check current spend in console to verify threshold crossing

## Integration with Other Clouds

This complements your existing cost management:
- **AWS**: See `deployments/aws/budgets/cost-management/`
- **Azure**: See Azure Cost Management + Budgets portal

## Free Tier Considerations

✅ **Budget API is FREE**
- No cost for creating budgets
- No cost for email notifications
- No cost for viewing budget data

💰 **Resources that incur costs:**
- Compute Engine instances
- Cloud Storage buckets
- Network egress
- Other GCP services

## Next Steps

1. ✅ Deploy budgets (you're here!)
2. 📊 Set up Cloud Monitoring alerts
3. 🔍 Review GCP cost recommendations
4. 📈 Track spending trends monthly
5. 🎯 Optimize high-cost services

## Additional Resources

- [GCP Billing Budgets Documentation](https://cloud.google.com/billing/docs/how-to/budgets)
- [Cost Management Best Practices](https://cloud.google.com/cost-management)
- [Billing Reports](https://cloud.google.com/billing/docs/how-to/reports)
- [Budget Alerts](https://cloud.google.com/billing/docs/how-to/budgets-notification-recipients)

---

**💡 Pro Tip**: Set your budget to slightly below your actual acceptable limit, so you get advance warning before hitting your true maximum!

Happy budget monitoring! 💰✨