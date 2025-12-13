# Azure Communication Services for Email Notifications

This Terraform module deploys Azure Communication Services with email domain configuration for sending notifications from app registration workflows.

## Overview

Azure Communication Services provides email capabilities for:
- Owner drift notifications (Day 0 and Day 7)
- Quarterly placeholder reviews
- Deployment notifications
- Escalation alerts

## Prerequisites

1. **Azure Subscription** with Communication Services quota
2. **Custom domain** (e.g., `notifications.yourcompany.com`)
3. **DNS access** to configure domain verification records
4. **Terraform** >= 1.3.0

## Quick Start

```bash
# Initialize Terraform
terraform init

# Plan deployment
terraform plan -var="domain_name=notifications.yourcompany.com"

# Deploy
terraform apply -var="domain_name=notifications.yourcompany.com"
```

## Configuration

Create a `terraform.tfvars` file:

```hcl
# Required variables
resource_group_name = "rg-communication-services"
location            = "eastus"
domain_name         = "notifications.yourcompany.com"
communication_service_name = "acs-app-registration-notifications"

# Optional
sender_username = "no-reply"  # Creates no-reply@notifications.yourcompany.com
tags = {
  Environment = "Production"
  Purpose     = "App Registration Notifications"
}
```

## Domain Verification

After running `terraform apply`:

1. **Get DNS records from output:**
   ```bash
   terraform output dns_verification_records
   ```

2. **Add TXT record to your DNS:**
   - **Name:** `@` or your subdomain
   - **Type:** `TXT`
   - **Value:** (from output)

3. **Wait for DNS propagation** (5-30 minutes)

4. **Verify domain in Azure Portal:**
   - Navigate to Communication Service
   - Go to "Domains"
   - Click "Verify"

## Sending Emails from Workflows

After domain verification, update GitHub repository secrets:

```bash
# Get connection string
az communication list-key \
  --name <communication-service-name> \
  --resource-group <resource-group-name> \
  --query primaryConnectionString -o tsv
```

Add to GitHub repository secrets:
- `AZURE_COMMUNICATION_SERVICES_CONNECTION_STRING`

## Email Templates

See [email-templates/](./email-templates/) for notification templates:
- `owner-drift-day0.html` - Initial disabled owner alert
- `owner-drift-day7.html` - Grace period expiration
- `placeholder-review.html` - Quarterly review
- `deployment-notification.html` - Deployment status

## Cost Estimation

Azure Communication Services pricing (as of 2024):

- **Email messages:** $0.00025 per email
- **Expected monthly volume:** ~50-100 emails
- **Estimated monthly cost:** < $1.00

## Integration with Workflows

Workflows will use Azure Communication Services for email notifications:

```yaml
- name: Send email notification
  run: |
    # Send email using Azure CLI or SDK
    az communication email send \
      --sender "no-reply@notifications.yourcompany.com" \
      --recipient "owner@company.com" \
      --subject "App Registration Alert" \
      --html-body "@email-templates/owner-drift-day0.html"
```

## Troubleshooting

### Domain verification fails
- Verify DNS records propagated: `nslookup -type=TXT notifications.yourcompany.com`
- Wait up to 30 minutes for propagation
- Ensure TXT record value matches exactly (no extra quotes/spaces)

### Emails not sending
- Check sender domain is verified
- Verify connection string is correct
- Check email is not in spam folder
- Review Azure Communication Services logs in portal

## Security Considerations

- **Connection string** is sensitive - store in GitHub Secrets only
- **SPF/DKIM records** should be configured for domain reputation
- **Rate limiting** is automatic (500 emails/hour default)
- **Audit logging** enabled by default

## Next Steps

After deployment:
1. Verify domain ownership
2. Add connection string to GitHub Secrets
3. Test email sending with sample workflow
4. Configure SPF/DKIM for production use

## See Also

- [Azure Communication Services Documentation](https://learn.microsoft.com/en-us/azure/communication-services/)
- [Email Domain Configuration](https://learn.microsoft.com/en-us/azure/communication-services/quickstarts/email/add-custom-verified-domains)
- [GitHub Actions Email Notifications](../../.github/workflows/app-registration-audit.yml)
