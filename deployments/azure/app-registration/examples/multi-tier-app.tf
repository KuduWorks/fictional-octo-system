# Example: Multi-Tier Application (Backend API + Frontend SPA)

# Backend API - Exposes custom scopes
module "backend_api" {
  source = "../"

  app_display_name = "todo-api-backend"
  sign_in_audience = "AzureADMyOrg"

  # Expose API with custom scopes
  expose_api = true
  api_scopes = [
    {
      id                         = "a1234567-89ab-cdef-0123-456789abcdef"
      value                      = "Tasks.Read"
      admin_consent_display_name = "Read tasks"
      admin_consent_description  = "Allows the application to read tasks on behalf of the user"
      user_consent_display_name  = "Read your tasks"
      user_consent_description   = "Allows the application to read your tasks"
    },
    {
      id                         = "b2345678-9abc-def0-1234-56789abcdef0"
      value                      = "Tasks.Write"
      admin_consent_display_name = "Create and update tasks"
      admin_consent_description  = "Allows the application to create and update tasks on behalf of the user"
      user_consent_display_name  = "Manage your tasks"
      user_consent_description   = "Allows the application to create and update your tasks"
    }
  ]

  # Backend needs to read user information
  graph_permissions = [
    {
      id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type  = "Scope"
      value = "User.Read"
    }
  ]

  secret_rotation_days = 90
  store_in_key_vault   = true
  key_vault_id         = azurerm_key_vault.backend.id

  tags = ["Tier:Backend", "ManagedByTerraform"]
}

# Frontend SPA - Consumes backend API
module "frontend_spa" {
  source = "../"

  app_display_name = "todo-web-frontend"
  sign_in_audience = "AzureADMyOrg"

  # SPA redirect URIs
  redirect_uris = [
    "http://localhost:3000",
    "https://todo.example.com"
  ]

  # Enable implicit flow for SPA (or use Auth Code with PKCE)
  enable_implicit_flow = false # Prefer PKCE over implicit flow

  # User sign-in permissions
  graph_permissions = [
    {
      id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type  = "Scope"
      value = "User.Read"
    }
  ]

  # Permission to call backend API
  custom_api_permissions = [
    {
      resource_app_id = module.backend_api.application_id
      permissions = [
        {
          id   = "a1234567-89ab-cdef-0123-456789abcdef" # Tasks.Read
          type = "Scope"
        },
        {
          id   = "b2345678-9abc-def0-1234-56789abcdef0" # Tasks.Write
          type = "Scope"
        }
      ]
    }
  ]

  secret_rotation_days = 90

  tags = ["Tier:Frontend", "ManagedByTerraform"]
}

# Backend Key Vault
resource "azurerm_key_vault" "backend" {
  name                = "kv-backend-api"
  location            = "East US"
  resource_group_name = "rg-todo-app"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete"]
  }
}

data "azurerm_client_config" "current" {}

# Outputs
output "backend_api_app_id_uri" {
  description = "Use this URI to reference the backend API"
  value       = "api://${module.backend_api.application_id}"
}

output "frontend_client_id" {
  description = "Frontend SPA Client ID"
  value       = module.frontend_spa.application_id
}

output "integration_example" {
  value = <<-EOT
    ╔════════════════════════════════════════════════════════════════╗
    ║              Multi-Tier Application Setup                      ║
    ╚════════════════════════════════════════════════════════════════╝
    
    Architecture:
    
    [Frontend SPA] --> [Backend API] --> [Microsoft Graph]
         |                  |
         |                  └─> Custom Scopes: Tasks.Read, Tasks.Write
         └─> User Sign-In (Azure AD)
    
    ────────────────────────────────────────────────────────────────
    Frontend Configuration (React/Angular/Vue):
    ────────────────────────────────────────────────────────────────
    
    // MSAL configuration
    const msalConfig = {
      auth: {
        clientId: "${module.frontend_spa.application_id}",
        authority: "https://login.microsoftonline.com/${module.frontend_spa.tenant_id}",
        redirectUri: "http://localhost:3000"
      }
    };
    
    // Request scopes for backend API
    const loginRequest = {
      scopes: [
        "api://${module.backend_api.application_id}/Tasks.Read",
        "api://${module.backend_api.application_id}/Tasks.Write"
      ]
    };
    
    ────────────────────────────────────────────────────────────────
    Backend API Configuration (Node.js/Python/C#):
    ────────────────────────────────────────────────────────────────
    
    # Environment variables
    AZURE_CLIENT_ID=${module.backend_api.application_id}
    AZURE_TENANT_ID=${module.backend_api.tenant_id}
    
    # JWT validation settings
    - Audience: api://${module.backend_api.application_id}
    - Issuer: https://login.microsoftonline.com/${module.backend_api.tenant_id}/v2.0
    - Valid scopes: Tasks.Read, Tasks.Write
    
    ────────────────────────────────────────────────────────────────
    API Endpoint Protection (Express.js example):
    ────────────────────────────────────────────────────────────────
    
    app.get('/api/tasks', 
      requireScope('Tasks.Read'),
      async (req, res) => {
        // User is authenticated and has Tasks.Read scope
        const userId = req.user.oid; // Object ID from token
        const tasks = await getTasks(userId);
        res.json(tasks);
      }
    );
    
    app.post('/api/tasks',
      requireScope('Tasks.Write'),
      async (req, res) => {
        // User has Tasks.Write scope
        const task = await createTask(req.user.oid, req.body);
        res.json(task);
      }
    );
  EOT
}
