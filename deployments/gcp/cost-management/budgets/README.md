# GCP Budget Management

> *"Because nobody likes surprise cloud bills"* 💰🚨

This module manages Google Cloud billing budgets and cost alerts to prevent surprise charges and monitor spending across your organization and individual projects.

## Features

- ✅ **Three-Tier Budget System**: Organization-wide + individual project budgets for granular cost control
- ✅ **Project-Specific Tracking**: Separate budgets for development and production projects
- ✅ **Immutable Project IDs**: Uses project IDs (not names) for stability when project names change
- ✅ **All Services Monitoring**: Tracks all GCP services across billing account and projects
- ✅ **Email Alerts**: Notifications at 50%, 80%, 100% thresholds (current spend only)
- ✅ **Budget Validation**: Ensures project budgets don't exceed organization budget
- ✅ **EUR Currency**: Configured for European billing accounts
- ✅ **Flexible Configuration**: Variable-driven budget amounts for easy adjustment

## Architecture

```
Organization Budget (€100/month)
├─ Dev Project Budget (€50/month)
│  └─ Project ID: centering-force-388308
└─ Prod Project Budget (€50/month)
   └─ Project ID: kudu-star-dev-01
```

### Budget Breakdown
| Budget Type | Default Amount | Scope | Alert Thresholds |
|-------------|---------------|-------|------------------|
| **Organization** | €100/month | Entire billing account | 50%, 80%, 100% |
| **Dev Project** | €50/month | Development project only | 50%, 80%, 100% |
| **Prod Project** | €50/month | Production project only | 50%, 80%, 100% |

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
# Billing Account ID
billing_account_id = "012345-6789AB-CDEFGH"  # From step 1

# Organization Budget (total for all projects)
monthly_budget_amount = 100  # EUR per month

# Project-Specific Budgets
dev_project_id            = "your-dev-project-id"      # Immutable project ID
prod_project_id           = "your-prod-project-id"     # Immutable project ID
dev_project_budget_amount = 50                         # EUR per month
prod_project_budget_amount = 50                        # EUR per month

# Email Notifications
budget_alert_emails = [
  "your.email@domain.com",
  "billing@domain.com"
]
```

**⚠️ Important**: Use immutable **project IDs** (not project names) to ensure budget stability if project display names change.

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
| **Organization Budget** | €100/month (configurable) | 50%, 80%, 100% | All services across entire billing account |
| **Dev Project Budget** | €50/month (configurable) | 50%, 80%, 100% | Development project only |
| **Prod Project Budget** | €50/month (configurable) | 50%, 80%, 100% | Production project only |
| **Email Notifications** | N/A | All budgets | Shared notification channels for all alerts |

## Alert Thresholds Explained

### Simplified Alert System (Current Spend Only)
- **50%** - Early warning, time to review spending patterns
- **80%** - High usage alert, monitor closely and consider optimization
- **100%** - Budget exceeded, immediate action required

**Note**: Forecasted spend alerts have been removed for simplicity. All alerts are based on actual current spending.

## Budget Configuration Example

For a €100 organization budget with €50 per project:
```
Organization Budget:   €100/month (Billing Account)
├─ Applies to:        All GCP services
├─ Scope:             Entire billing account
├─ Alerts:            50%, 80%, 100%
│
├─ Dev Project:       €50/month (Project: centering-force-388308)
│  ├─ Applies to:     All services in dev project
│  ├─ Scope:          Development project only
│  └─ Alerts:         50%, 80%, 100%
│
└─ Prod Project:      €50/month (Project: kudu-star-dev-01)
   ├─ Applies to:     All services in prod project
   ├─ Scope:          Production project only
   └─ Alerts:         50%, 80%, 100%
```

### Budget Validation
- ✅ Dev budget + Prod budget ≤ Organization budget
- ✅ All budget amounts must be non-negative
- ✅ Project IDs validated for GCP format (6-30 chars, lowercase, digits, hyphens)

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

### Change Organization Budget Limit
```hcl
# In terraform.tfvars
monthly_budget_amount = 200  # Increase to €200/month
```

### Adjust Individual Project Budgets
```hcl
# In terraform.tfvars
dev_project_budget_amount = 75   # Increase dev to €75/month
prod_project_budget_amount = 125 # Increase prod to €125/month
# Note: Sum must not exceed monthly_budget_amount (€200 in this case)
```

### Add/Change Project IDs
```hcl
# In terraform.tfvars
dev_project_id = "new-dev-project-id"
prod_project_id = "new-prod-project-id"
# Use immutable project IDs, not display names
```

### Add More Email Recipients
```hcl
# In terraform.tfvars
budget_alert_emails = [
  "devops@domain.com",
  "finance@domain.com",
  "billing@domain.com"
]
```

### Customize Alert Thresholds (Advanced)
Edit [main.tf](main.tf) to customize alert percentages:
```terraform
# Modify threshold rules in any budget resource
threshold_rules {
  threshold_percent = 0.6   # Alert at 60% instead of 80%
  spend_basis       = "CURRENT_SPEND"
}
```

## Configuration Variables

| Variable | Type | Default | Description | Required |
|----------|------|---------|-------------|----------|
| `billing_account_id` | string | `""` | GCP billing account ID | ✅ Yes |
| `monthly_budget_amount` | number | `100` | Organization budget (EUR/month) | No |
| `dev_project_id` | string | `""` | Dev project immutable ID | Conditional* |
| `prod_project_id` | string | `""` | Prod project immutable ID | Conditional* |
| `dev_project_budget_amount` | number | `50` | Dev project budget (EUR/month) | No |
| `prod_project_budget_amount` | number | `50` | Prod project budget (EUR/month) | No |
| `budget_alert_emails` | list(string) | `[]` | Email addresses for alerts | No |
| `environment` | string | `"dev"` | Environment name | No |
| `gcp_region` | string | `"europe-north1"` | GCP region | No |

**Conditional**: Project budgets are only created if project IDs are provided. Leave empty to disable project-specific budgets.

## Cost Optimization Tips

1. **Set Realistic Budgets**: Start conservative, adjust based on actual usage patterns
2. **Monitor Regularly**: Review alerts weekly, investigate unexpected spending
3. **Use Project Budgets**: Identify which project/environment is driving costs
4. **Enable Recommendations**: GCP provides automated cost optimization suggestions
5. **Review Unused Resources**: Delete idle VMs, old snapshots, unused storage
6. **Use Immutable Project IDs**: Prevents budget loss if project names change
7. **Validate Budget Sums**: Ensure project budgets don't exceed org budget (validation enforced)
8. **Track by Project**: Separate dev/prod helps identify optimization opportunities

## Troubleshooting

### "Permission denied" error
```bash
# Ensure you have billing admin permissions
gcloud projects add-iam-policy-binding YOUR-PROJECT-ID \
  --member="user:YOUR-EMAIL@domain.com" \
  --role="roles/billing.admin"
```

### Email notifications not received
1. Check email addresses in [terraform.tfvars](terraform.tfvars)
2. Verify notification channels: `terraform output notification_channels`
3. Check spam/junk folders
4. Confirm billing account is active
5. Ensure emails are not blocked by corporate filters

### Budget not triggering alerts
- Budgets need actual spend data to trigger (24-48 hours for initial data)
- Check current spend in console to verify threshold crossing
- Verify project IDs are correct (use `gcloud projects list`)
- Ensure billing is enabled for projects

### Validation error: "project budgets exceed org budget"
```hcl
# Ensure sum of project budgets ≤ org budget
# Example fix in terraform.tfvars:
monthly_budget_amount = 150        # Organization total
dev_project_budget_amount = 75     # Dev
prod_project_budget_amount = 75    # Prod
# Sum: 75 + 75 = 150 ✅ Valid
```

### Project budget not created
- Check that `dev_project_id` or `prod_project_id` is set
- Verify project ID format (6-30 chars, lowercase, digits, hyphens)
- Confirm billing is linked to the projects: `gcloud billing projects list --billing-account=YOUR-BILLING-ACCOUNT-ID`

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

1. ✅ Deploy three-tier budget system (you're here!)
2. 📊 Set up Cloud Monitoring dashboards for cost visualization
3. 🔍 Review GCP cost recommendations in billing console
4. 📈 Track spending trends by project monthly
5. 🎯 Optimize high-cost services identified in project budgets
6. 🔔 Set up additional alerts for specific services if needed
7. 📝 Document cost attribution per team/project

## Security Best Practices

- ✅ **No Sensitive Data in Examples**: [terraform.tfvars.example](terraform.tfvars.example) uses placeholders only
- ✅ **Immutable Project IDs**: Uses project IDs for stability (not display names)
- ✅ **Gitignore Protection**: Actual [terraform.tfvars](terraform.tfvars) should be in `.gitignore`
- ✅ **Email Validation**: Only specified emails receive alerts
- ✅ **Billing Permissions**: Requires `roles/billing.admin` for budget management

## Additional Resources

- [GCP Billing Budgets Documentation](https://cloud.google.com/billing/docs/how-to/budgets)
- [Cost Management Best Practices](https://cloud.google.com/cost-management)
- [Billing Reports](https://cloud.google.com/billing/docs/how-to/reports)
- [Budget Alerts](https://cloud.google.com/billing/docs/how-to/budgets-notification-recipients)
- [Project ID vs Project Name](https://cloud.google.com/resource-manager/docs/creating-managing-projects)

---

**💡 Pro Tip**: Use immutable project IDs (not names) to ensure your budgets remain stable when teams rename projects. Set project budgets slightly below expected spend for advance warning!

Happy budget monitoring! 💰✨