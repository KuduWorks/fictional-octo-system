# GCP Essential Contacts

> *"Because security alerts sent to /dev/null don't help anyone"* 📧🔔

This Terraform module configures organization-level Essential Contacts for security, billing, and monitoring notifications in Google Cloud Platform.

## What This Module Does

Creates three separate Essential Contacts to receive critical notifications:

1. **Security Contact** → SECURITY + TECHNICAL notifications
   - Security incidents, vulnerability alerts
   - Critical updates, compliance issues
   
2. **Billing Contact** → BILLING notifications
   - Billing anomalies, budget alerts
   - Payment issues, cost overruns

3. **Monitoring Contact** → TECHNICAL + SUSPENSION notifications
   - Service suspensions, quota issues
   - Operational alerts, technical problems

## Prerequisites

- **GCP Organization** (required - this is organization-level)
- **Organization Admin role** or `resourcemanager.organizationAdmin`
- **Essential Contacts API** enabled (done automatically by module)
- **Terraform** >= 1.0
- **Google Provider** ~> 5.0

## Quick Start

### 1. Configure Your Values

```bash
# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values
nano terraform.tfvars
```

Update these values:
- `organization_id`: Your GCP organization ID (numeric, e.g., `123456789012`)
- `project_id`: Bootstrap project where API will be enabled
- `security_contact_email`: Team/individual email for security alerts
- `billing_contact_email`: Finance team email for billing notifications
- `monitoring_contact_email`: Operations team email for technical alerts

### 2. Set Up Backend (First Time Only)

```bash
# Copy backend template
cp backend.tf.example backend.tf

# Update with your project ID
sed -i 's/<YOUR-PROJECT-ID>/your-actual-project-id/g' backend.tf
```

### 3. Deploy

```bash
# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Apply configuration
terraform apply
```

## Finding Your Organization ID

```bash
# Using gcloud CLI
gcloud organizations list

# Output shows:
# DISPLAY_NAME       ID            DIRECTORY_CUSTOMER_ID
# kuduworks.net      123456789012  C01abc123
#                    ^^^^^^^^^^^^
#                    This is your organization_id
```

Or via Cloud Console:
1. Go to https://console.cloud.google.com/cloud-resource-manager
2. Organization ID shown next to your organization name

## Configuration Example

```hcl
# terraform.tfvars
organization_id = "123456789012"
project_id      = "my-bootstrap-project"

security_contact_email   = "security@kuduworks.net"
billing_contact_email    = "billing@kuduworks.net"
monitoring_contact_email = "ops@kuduworks.net"
```

## Notification Categories

| Category | Receives | Example Alerts |
|----------|----------|----------------|
| **SECURITY** | Security team | Data breaches, vulnerabilities, compliance violations |
| **BILLING** | Finance team | Budget exceeded, payment failures, cost anomalies |
| **TECHNICAL** | Both security & ops | API quota issues, service degradation, config problems |
| **SUSPENSION** | Operations team | Service suspensions, account restrictions |

## Email Validation

⚠️ **Important**: Contacts must **verify their email** via link sent by Google.

**After deployment:**
1. Check inbox for "Verify your Essential Contact email"
2. Click verification link (expires in 14 days)
3. Repeat for all three contact emails

**Check verification status:**
```bash
gcloud essential-contacts list --organization=<YOUR-ORG-ID>

# Look for "validationState: VALID" in output
```

## Outputs

```bash
terraform output

# Shows:
# - Security contact details (email, categories, validation state)
# - Billing contact details
# - Monitoring contact details
# - Summary with verification instructions
```

## Cost

**$0.00/month** ✅

Essential Contacts is a free GCP service - no charges for:
- Creating contacts
- Receiving notifications
- Email delivery
- API usage

## Integration with Other Security Modules

Essential Contacts work seamlessly with:

1. **Organization Policies** ([../../organization/policies/](../../organization/policies/))
   - Violation alerts sent to security contact
   
2. **Service Account Audits** ([../../organization/scripts/](../../organization/scripts/))
   - GitHub Issues + email notifications to monitoring contact
   
3. **Budget Alerts** ([../../cost-management/](../../cost-management/))
   - Cost overruns sent to billing contact

## Troubleshooting

### "Organization not found"

**Cause**: Invalid organization ID or missing permissions

**Fix**:
```bash
# Verify organization exists
gcloud organizations list

# Check your permissions
gcloud organizations get-iam-policy <YOUR-ORG-ID> \
  --filter="bindings.members:user:your-email@domain.com"
```

### "Essential Contacts API not enabled"

**Cause**: API not activated in project

**Fix**: Module enables it automatically, but if manual needed:
```bash
gcloud services enable essentialcontacts.googleapis.com \
  --project=<YOUR-PROJECT-ID>
```

### "Email not validated"

**Cause**: Contact didn't verify email within 14 days

**Fix**:
```bash
# Resend verification email
gcloud essential-contacts compute <contact-email> \
  --organization=<YOUR-ORG-ID>
```

### "Insufficient permissions"

**Cause**: Missing `resourcemanager.organizationAdmin` or equivalent

**Fix**:
```bash
# Grant organization admin role
gcloud organizations add-iam-policy-binding <YOUR-ORG-ID> \
  --member="user:your-email@domain.com" \
  --role="roles/resourcemanager.organizationAdmin"
```

## Testing Notifications

**Send test notification** (requires Essential Contacts API):

```bash
# Trigger test security alert
gcloud essential-contacts compute security@your-domain.com \
  --organization=<YOUR-ORG-ID> \
  --notification-category-subscriptions=SECURITY

# Check contact receives email
```

## Module Structure

```
essential-contacts/
├── main.tf                    # Contact resources
├── variables.tf              # Input variables
├── outputs.tf                # Output values
├── provider.tf               # GCP provider config
├── backend.tf.example        # State storage template
├── terraform.tfvars.example  # Configuration template
├── .gitignore               # Exclude secrets from git
└── README.md                # This file
```

## Security Best Practices

✅ **DO:**
- Use distribution lists/group emails (e.g., security-team@domain.com)
- Verify all contact emails promptly
- Review contacts quarterly (ensure still valid)
- Use dedicated emails per category (don't reuse)
- Test notification delivery periodically

❌ **DON'T:**
- Use personal emails (what if person leaves?)
- Ignore verification emails (contact won't receive alerts!)
- Use same email for all categories (hard to route)
- Share credentials for contact emails
- Commit `terraform.tfvars` to git (contains your org ID)

## Next Steps

After deploying Essential Contacts:

1. ✅ **Verify all emails** (check inboxes for verification links)
2. 📋 **Deploy Organization Policies** ([../../organization/policies/](../../organization/policies/))
3. 🔍 **Set up Security Audits** ([../../organization/scripts/](../../organization/scripts/))
4. 🤖 **Enable GitHub Actions** quarterly audit workflow
5. 💰 **Configure Budget Alerts** to trigger billing contact

## Additional Resources

- [Essential Contacts Documentation](https://cloud.google.com/resource-manager/docs/managing-notification-contacts)
- [GCP Organization Best Practices](https://cloud.google.com/resource-manager/docs/organization-policy/overview)
- [Notification Categories Reference](https://cloud.google.com/resource-manager/docs/managing-notification-contacts#notification-categories)

---

**💡 Pro Tip**: Use Google Groups for contact emails - easier to manage team changes without updating Terraform!

**Cost: $0.00/month** 💰✨
