# GCP Budget Management

> *"Because nobody likes surprise cloud bills"* 💰🚨

This module manages Google Cloud billing budgets and cost alerts to prevent surprise charges and monitor spending.

## Features

- ✅ **Monthly Budget**: Overall project spending limit with multi-threshold alerts
- ✅ **Compute Budget**: Dedicated monitoring for Compute Engine costs
- ✅ **Storage Budget**: Track Cloud Storage expenses separately
- ✅ **Email Alerts**: Notifications at 50%, 75%, 90%, 100% thresholds
- ✅ **Forecast Alerts**: Predict when budget will be exceeded based on trends
- ✅ **Multi-Service Tracking**: Separate budgets per service category

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
monthly_budget_amount = 50                    # USD per month
budget_alert_emails = [
  "your.email@domain.com"
]
```

### Step 3: Configure Backend

```bash
# Copy backend configuration
cp backend.tf.example backend.tf

# Update with your project ID
sed -i 's/PROJECT-ID/kudu-star-dev-01/g' backend.tf
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
| **Monthly Budget** | 100% of limit | 50%, 75%, 90%, 100%, Forecast | Overall project spending |
| **Compute Budget** | 50% of limit | 80%, 100% | Compute Engine instances |
| **Storage Budget** | 20% of limit | 80%, 100% | Cloud Storage costs |

## Alert Thresholds Explained

### Main Budget Alerts
- **50%** - Early warning, time to review spending
- **75%** - Check if projections are on track
- **90%** - High alert, consider cost optimization
- **100%** - Budget exceeded, immediate action needed
- **100% Forecast** - Predicted to exceed budget this month

### Service Budget Alerts
- **80%** - Service approaching its allocation
- **100%** - Service exceeded its budget allocation

## Budget Calculation Example

For a $100 monthly budget:
```
Total Budget:   $100/month
├─ Compute:     $50 (50%) - VMs, GKE, etc.
├─ Storage:     $20 (20%) - GCS buckets
└─ Other:       $30 (30%) - Networking, APIs, etc.
```

## Viewing Budgets

### Web Console
```
https://console.cloud.google.com/billing/budgets?project=kudu-star-dev-01
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
monthly_budget_amount = 200  # Increase to $200/month
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

### Adjust Service Allocations
Edit `main.tf` to change percentages:
```terraform
# Compute budget (currently 50%)
units = tostring(var.monthly_budget_amount * 0.7)  # Change to 70%

# Storage budget (currently 20%)
units = tostring(var.monthly_budget_amount * 0.1)  # Change to 10%
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
gcloud projects add-iam-policy-binding kudu-star-dev-01 \
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