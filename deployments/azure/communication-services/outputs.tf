output "communication_service_id" {
  description = "Resource ID of the Communication Service"
  value       = azurerm_communication_service.acs.id
}

output "communication_service_endpoint" {
  description = "Endpoint URL for the Communication Service"
  value       = azurerm_communication_service.acs.primary_connection_string
  sensitive   = true
}

output "email_service_id" {
  description = "Resource ID of the Email Communication Service"
  value       = azurerm_email_communication_service.email.id
}

output "custom_domain_id" {
  description = "Resource ID of the custom email domain"
  value       = azurerm_email_communication_service_domain.custom_domain.id
}

output "sender_email_address" {
  description = "Sender email address for notifications"
  value       = "${var.sender_username}@${var.domain_name}"
}

output "dns_verification_instructions" {
  description = "Instructions for DNS verification"
  value       = <<-EOT
    To verify your domain, add the following DNS records:
    
    1. Log in to your DNS provider
    2. Add a TXT record:
       - Name: @ (or your subdomain if using one)
       - Type: TXT
       - Value: (Get from Azure Portal -> Communication Service -> Domains -> Verification)
    
    3. Wait 5-30 minutes for DNS propagation
    4. Verify domain in Azure Portal
    
    You can check DNS propagation with:
    nslookup -type=TXT ${var.domain_name}
  EOT
}

output "connection_string_secret_command" {
  description = "Command to retrieve connection string for GitHub Secrets"
  value       = <<-EOT
    Run this command to get the connection string:
    
    az communication list-key \
      --name ${var.communication_service_name} \
      --resource-group ${var.resource_group_name} \
      --query primaryConnectionString -o tsv
    
    Then add to GitHub repository secrets as:
    AZURE_COMMUNICATION_SERVICES_CONNECTION_STRING
  EOT
}

output "next_steps" {
  description = "Next steps after deployment"
  value       = <<-EOT
    Next Steps:
    
    1. Verify Domain:
       - Get DNS verification records from Azure Portal
       - Add TXT record to your DNS
       - Wait for propagation (5-30 minutes)
       - Click 'Verify' in Azure Portal
    
    2. Configure GitHub Secrets:
       - Run: terraform output connection_string_secret_command
       - Add connection string to GitHub repository secrets
    
    3. Test Email Sending:
       - Run a test workflow to send sample email
       - Check spam folder if not received
    
    4. Production Setup:
       - Configure SPF record for domain reputation
       - Configure DKIM for email authentication
       - Set up monitoring alerts
    
    Sender Address: ${var.sender_username}@${var.domain_name}
  EOT
}
