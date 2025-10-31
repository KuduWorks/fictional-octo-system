# Example: Background Service with Application Permissions

module "daemon_service" {
  source = "../"

  app_display_name = "user-sync-daemon"
  sign_in_audience = "AzureADMyOrg"

  # No redirect URIs needed for daemon applications

  # Application permissions (runs without user interaction)
  graph_permissions = [
    {
      id    = "df021288-bdef-4463-88db-98f22de89214" # User.Read.All
      type  = "Role"                                 # Application permission
      value = "User.Read.All"
    },
    {
      id    = "5b567255-7703-4780-807c-7be8301ae99b" # Group.Read.All
      type  = "Role"
      value = "Group.Read.All"
    },
    {
      id    = "62a82d76-70ea-41e2-9197-370581804d09" # Group.ReadWrite.All
      type  = "Role"
      value = "Group.ReadWrite.All"
    }
  ]

  # Application permissions require admin consent
  grant_admin_consent = true

  # Notification emails for service principal changes
  notification_emails = ["ops-team@example.com", "security@example.com"]

  # Secret rotation
  secret_rotation_days = 90

  # Store credentials in Key Vault
  store_in_key_vault = true
  key_vault_id       = azurerm_key_vault.main.id

  tags = {
    Environment = "Production"
    ServiceType = "Daemon"
    ManagedBy   = "Terraform"
  }
}

# Sample Key Vault (if not already exists)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "kv-daemon-secrets"
  location                   = "East US"
  resource_group_name        = "rg-daemon-service"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  # Allow Terraform to manage secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Purge", "Recover"
    ]
  }

  # Allow the service principal to read its own secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = module.daemon_service.service_principal_id

    secret_permissions = [
      "Get", "List"
    ]
  }
}

# Outputs
output "daemon_client_id" {
  value = module.daemon_service.application_id
}

output "daemon_secret_location" {
  value = "Stored in Key Vault: ${azurerm_key_vault.main.name}"
}

output "next_rotation_date" {
  value = module.daemon_service.secret_rotation_date
}

# Python example for daemon service
output "python_example" {
  value = <<-EOT
    # Python example using MSAL (Microsoft Authentication Library)
    
    from azure.identity import ClientSecretCredential
    from azure.keyvault.secrets import SecretClient
    import requests
    
    # Get credentials from Key Vault
    credential = ClientSecretCredential(
        tenant_id="${module.daemon_service.tenant_id}",
        client_id="${module.daemon_service.application_id}",
        client_secret="<from-environment-or-keyvault>"
    )
    
    # Get access token for Microsoft Graph
    token = credential.get_token("https://graph.microsoft.com/.default")
    
    # Call Microsoft Graph API
    headers = {"Authorization": f"Bearer {token.token}"}
    response = requests.get(
        "https://graph.microsoft.com/v1.0/users",
        headers=headers
    )
    
    users = response.json()
    print(f"Found {len(users.get('value', []))} users")
  EOT
}
