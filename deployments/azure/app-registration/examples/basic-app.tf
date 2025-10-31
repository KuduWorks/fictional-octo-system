# Example: Basic Application Registration with User Sign-In

module "basic_app" {
  source = "../"

  app_display_name = "my-web-app"
  sign_in_audience = "AzureADMyOrg"

  # Web application redirect URIs
  redirect_uris = [
    "https://localhost:3000/auth/callback",
    "https://myapp.example.com/auth/callback"
  ]

  # Basic delegated permissions for user sign-in
  graph_permissions = [
    {
      id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type  = "Scope"                                # Delegated permission
      value = "User.Read"
    },
    {
      id    = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0" # email
      type  = "Scope"
      value = "email"
    },
    {
      id    = "14dad69e-099b-42c9-810b-d002981feec1" # profile
      type  = "Scope"
      value = "profile"
    }
  ]

  secret_rotation_days = 90

  tags = ["Environment:Development", "ManagedByTerraform"]
}

# Outputs
output "client_id" {
  description = "Use this Client ID in your application configuration"
  value       = module.basic_app.application_id
}

output "tenant_id" {
  description = "Your Azure AD Tenant ID"
  value       = module.basic_app.tenant_id
}

output "client_secret" {
  description = "Client Secret (store securely!)"
  value       = module.basic_app.client_secret
  sensitive   = true
}

# Usage in your application
output "environment_variables" {
  description = "Set these environment variables in your application"
  value       = <<-EOT
    export AZURE_CLIENT_ID="${module.basic_app.application_id}"
    export AZURE_CLIENT_SECRET="${module.basic_app.client_secret}"
    export AZURE_TENANT_ID="${module.basic_app.tenant_id}"
    export AZURE_REDIRECT_URI="https://localhost:3000/auth/callback"
  EOT
  sensitive   = true
}
