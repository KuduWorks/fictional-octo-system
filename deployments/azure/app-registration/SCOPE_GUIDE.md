# Graph vs. Resource-Specific Scopes: A Decision Guide

This guide helps you choose between Microsoft Graph API permissions and resource-specific API permissions when building Azure applications.

## 🎯 Quick Decision Tree

```
Need to access Azure resources (VMs, Storage, etc.)?
├─ YES → Use Azure Resource Manager (ARM) API
│         or resource-specific APIs (Storage, Key Vault)
│
└─ NO → Need to access Microsoft 365 data?
         ├─ YES → Use Microsoft Graph API
         │
         └─ NO → Accessing your own custom API?
                  └─ YES → Use custom API permissions
```

## 📊 Comparison Table

| Aspect | Microsoft Graph | Azure Resource Manager | Custom APIs |
|--------|----------------|------------------------|-------------|
| **Purpose** | Microsoft 365 & Azure AD data | Azure infrastructure | Your services |
| **Base URL** | `graph.microsoft.com` | `management.azure.com` | Your domain |
| **Auth Scope** | `https://graph.microsoft.com/.default` | `https://management.azure.com/.default` | `api://your-app-id/.default` |
| **Common Use** | Users, Groups, Mail, Teams | VMs, Storage, Resource Groups | Business logic |
| **Admin Consent** | Often required | Required for elevated roles | Configurable |

## 🔵 Microsoft Graph: When to Use

### ✅ Use Microsoft Graph When You Need To:

#### 1. User & Identity Management
```hcl
# Reading user profiles, managing users
graph_permissions = [
  {
    id    = "df021288-bdef-4463-88db-98f22de89214"  # User.Read.All
    type  = "Role"
    value = "User.Read.All"
  }
]
```

**Examples:**
- Display user profile in your app
- Search for users in your organization
- User provisioning/synchronization
- Reading organizational structure

#### 2. Email & Calendar Integration
```hcl
# Sending emails, managing calendars
graph_permissions = [
  {
    id    = "e383f46e-2787-4529-855e-0e479a3ffac0"  # Mail.Send
    type  = "Scope"
    value = "Mail.Send"
  },
  {
    id    = "1ec239c2-d7c9-4623-a91a-a9775856bb36"  # Calendars.ReadWrite
    type  = "Scope"
    value = "Calendars.ReadWrite"
  }
]
```

**Examples:**
- Send notification emails via Outlook
- Read user's calendar for scheduling
- Create meeting invites
- Access shared mailboxes

#### 3. Teams & SharePoint
```hcl
# Working with Teams and SharePoint
graph_permissions = [
  {
    id    = "2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e"  # Team.ReadBasic.All
    type  = "Role"
    value = "Team.ReadBasic.All"
  },
  {
    id    = "332a536c-c7ef-4017-ab91-336970924f0d"  # Sites.Read.All
    type  = "Role"
    value = "Sites.Read.All"
  }
]
```

**Examples:**
- List Teams channels
- Read SharePoint documents
- Create Teams notifications
- Access OneNote notebooks

#### 4. Security & Compliance
```hcl
# Reading audit logs, managing policies
graph_permissions = [
  {
    id    = "b0afded3-3588-46d8-8b3d-9842eff778da"  # AuditLog.Read.All
    type  = "Role"
    value = "AuditLog.Read.All"
  }
]
```

**Examples:**
- Compliance reporting
- Security event monitoring
- Conditional access policy management
- Audit log analysis

### 📝 Microsoft Graph Example

```python
from azure.identity import ClientSecretCredential
import requests

# Authenticate
credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-secret"
)

# Get token for Microsoft Graph
token = credential.get_token("https://graph.microsoft.com/.default")

# Call Graph API
headers = {"Authorization": f"Bearer {token.token}"}
response = requests.get(
    "https://graph.microsoft.com/v1.0/users",
    headers=headers
)

users = response.json()
```

## 🔷 Azure Resource Manager: When to Use

### ✅ Use ARM API When You Need To:

#### 1. Infrastructure Management
```hcl
# Managing Azure resources
arm_permissions = [
  {
    id    = "41094075-9dad-400e-a0bd-54e686782033"  # user_impersonation
    type  = "Scope"
    value = "user_impersonation"
  }
]

# Then grant RBAC roles
resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.app_sp.object_id
}
```

**Examples:**
- Deploy VMs, App Services, Storage
- Create resource groups
- Manage networking (VNets, NSGs)
- Tag and organize resources

#### 2. Cost Management
```python
# Reading cost data
token = credential.get_token("https://management.azure.com/.default")

response = requests.get(
    "https://management.azure.com/subscriptions/{subscription-id}/providers/Microsoft.CostManagement/query",
    headers={"Authorization": f"Bearer {token.token}"},
    params={"api-version": "2021-10-01"}
)
```

**Examples:**
- Generate cost reports
- Set budget alerts
- Analyze resource usage
- Optimize spending

#### 3. Monitoring & Diagnostics
```hcl
# Grant monitoring permissions
resource "azurerm_role_assignment" "monitoring" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.app_sp.object_id
}
```

**Examples:**
- Read metrics from Azure Monitor
- Query Log Analytics workspaces
- Set up alerts
- Access Application Insights

### 📝 ARM API Example

```python
from azure.identity import ClientSecretCredential
from azure.mgmt.resource import ResourceManagementClient

# Authenticate
credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-secret"
)

# Create ARM client
resource_client = ResourceManagementClient(credential, subscription_id)

# List resource groups
for rg in resource_client.resource_groups.list():
    print(f"Resource Group: {rg.name}, Location: {rg.location}")
```

## 🟢 Resource-Specific APIs: When to Use

### ✅ Use Resource-Specific APIs When You Need To:

#### 1. Azure Storage (Direct Access)
```python
from azure.identity import ClientSecretCredential
from azure.storage.blob import BlobServiceClient

# Use credential directly with Storage SDK
credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-secret"
)

# No Graph permissions needed!
blob_service = BlobServiceClient(
    account_url="https://mystorageaccount.blob.core.windows.net",
    credential=credential
)

# Or use Managed Identity / RBAC
```

**Terraform: Grant Storage access**
```hcl
resource "azurerm_role_assignment" "storage_contributor" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.app_sp.object_id
}
```

#### 2. Azure Key Vault (Direct Access)
```python
from azure.identity import ClientSecretCredential
from azure.keyvault.secrets import SecretClient

credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-secret"
)

# Access Key Vault directly
secret_client = SecretClient(
    vault_url="https://myvault.vault.azure.net",
    credential=credential
)

secret = secret_client.get_secret("my-secret")
```

**Terraform: Grant Key Vault access**
```hcl
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = azuread_service_principal.app_sp.object_id

  secret_permissions = ["Get", "List"]
}
```

#### 3. Azure SQL Database
```python
import pyodbc
from azure.identity import ClientSecretCredential

credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-secret"
)

# Get access token for Azure SQL
token = credential.get_token("https://database.windows.net/.default")

# Connect using Azure AD token
conn = pyodbc.connect(
    f"Driver={{ODBC Driver 18 for SQL Server}};"
    f"Server=tcp:myserver.database.windows.net,1433;"
    f"Database=mydb;"
    f"Authentication=ActiveDirectoryAccessToken;"
    f"AccessToken={token.token}"
)
```

#### 4. Cosmos DB (Direct Access)
```python
from azure.cosmos import CosmosClient
from azure.identity import ClientSecretCredential

credential = ClientSecretCredential(
    tenant_id="your-tenant-id",
    client_id="your-client-id",
    client_secret="your-secret"
)

# Use RBAC instead of connection strings
client = CosmosClient(
    url="https://mycosmosdb.documents.azure.com:443/",
    credential=credential
)
```

## 🟣 Custom APIs: When to Use

### ✅ Use Custom API Permissions When:

You're building a multi-tier application where:
- **Backend API** exposes custom scopes
- **Frontend/Client** calls the backend

```hcl
# Backend API - Expose scopes
module "backend_api" {
  source = "./app-registration"

  app_display_name = "my-backend-api"
  expose_api       = true
  
  api_scopes = [
    {
      id                         = "a1234567-89ab-cdef-0123-456789abcdef"
      value                      = "Tasks.Read"
      admin_consent_display_name = "Read tasks"
      admin_consent_description  = "Allows reading tasks"
      user_consent_display_name  = "Read your tasks"
      user_consent_description   = "Allows reading your tasks"
    }
  ]
}

# Frontend - Request backend scopes
module "frontend" {
  source = "./app-registration"

  app_display_name = "my-frontend"
  
  custom_api_permissions = [
    {
      resource_app_id = module.backend_api.application_id
      permissions = [
        {
          id   = "a1234567-89ab-cdef-0123-456789abcdef"  # Tasks.Read
          type = "Scope"
        }
      ]
    }
  ]
}
```

### 📝 Custom API Example

**Backend (Express.js):**
```javascript
const passport = require('passport');
const BearerStrategy = require('passport-azure-ad').BearerStrategy;

const options = {
  identityMetadata: `https://login.microsoftonline.com/${tenantId}/v2.0/.well-known/openid-configuration`,
  clientID: process.env.CLIENT_ID,
  audience: `api://${process.env.CLIENT_ID}`,
  validateIssuer: true,
  issuer: `https://login.microsoftonline.com/${tenantId}/v2.0`,
  loggingLevel: 'info',
  passReqToCallback: false
};

passport.use(new BearerStrategy(options, (token, done) => {
  // Verify token has required scope
  if (!token.scp || !token.scp.includes('Tasks.Read')) {
    return done(null, false, { message: 'Insufficient scope' });
  }
  return done(null, token);
}));

// Protected endpoint
app.get('/api/tasks',
  passport.authenticate('oauth-bearer', { session: false }),
  (req, res) => {
    res.json({ tasks: [...] });
  }
);
```

**Frontend (React with MSAL):**
```javascript
import { PublicClientApplication } from "@azure/msal-browser";

const msalConfig = {
  auth: {
    clientId: "frontend-client-id",
    authority: "https://login.microsoftonline.com/tenant-id",
    redirectUri: "http://localhost:3000"
  }
};

const pca = new PublicClientApplication(msalConfig);

// Request token for backend API
const request = {
  scopes: ["api://backend-client-id/Tasks.Read"]
};

const response = await pca.acquireTokenSilent(request);

// Call backend with token
fetch('https://api.example.com/api/tasks', {
  headers: {
    'Authorization': `Bearer ${response.accessToken}`
  }
});
```

## 🎓 Real-World Scenarios

### Scenario 1: Employee Directory App

**Need:** Display user profiles, send notifications

**Solution:** Use **Microsoft Graph**
```hcl
graph_permissions = [
  { id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d", type = "Scope", value = "User.Read" },
  { id = "e383f46e-2787-4529-855e-0e479a3ffac0", type = "Scope", value = "Mail.Send" }
]
```

### Scenario 2: Infrastructure Automation

**Need:** Deploy VMs, manage resource groups

**Solution:** Use **Azure Resource Manager**
```hcl
arm_permissions = [
  { id = "41094075-9dad-400e-a0bd-54e686782033", type = "Scope", value = "user_impersonation" }
]

# Grant RBAC roles
resource "azurerm_role_assignment" "contributor" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.app_sp.object_id
}
```

### Scenario 3: Data Processing Pipeline

**Need:** Read from Storage, write to SQL, log to Key Vault

**Solution:** Use **Resource-Specific APIs + RBAC**
```hcl
# No Graph permissions needed!

# Storage access
resource "azurerm_role_assignment" "storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.app_sp.object_id
}

# SQL access
resource "azurerm_mssql_server_azure_ad_administrator" "admin" {
  server_name         = azurerm_mssql_server.main.name
  resource_group_name = azurerm_resource_group.main.name
  login_username      = "app-service-principal"
  object_id           = azuread_service_principal.app_sp.object_id
}

# Key Vault access
resource "azurerm_key_vault_access_policy" "app" {
  key_vault_id = azurerm_key_vault.main.id
  object_id    = azuread_service_principal.app_sp.object_id
  secret_permissions = ["Get", "List"]
}
```

### Scenario 4: SaaS Application

**Need:** Multi-tenant app with users, custom business logic

**Solution:** Use **Microsoft Graph + Custom API**
```hcl
# App registration with both
graph_permissions = [
  { id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d", type = "Scope", value = "User.Read" }
]

expose_api = true
api_scopes = [
  {
    id    = "custom-scope-id"
    value = "Customers.Read"
    # ... other fields
  }
]
```

## 🚫 Common Mistakes

### ❌ Mistake 1: Using Graph for Azure Resources
```hcl
# WRONG: Can't use Graph to manage VMs
graph_permissions = [
  { id = "???", type = "Role", value = "VirtualMachines.Read" }  # Doesn't exist!
]
```

**✅ Correct:**
```hcl
# Use ARM API + RBAC
resource "azurerm_role_assignment" "vm_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_service_principal.app_sp.object_id
}
```

### ❌ Mistake 2: Over-requesting Permissions
```hcl
# WRONG: Requesting too many permissions
graph_permissions = [
  { id = "...", type = "Role", value = "Directory.ReadWrite.All" },  # Too broad!
  { id = "...", type = "Role", value = "User.ReadWrite.All" },       # Too broad!
]
```

**✅ Correct:**
```hcl
# Request only what you need
graph_permissions = [
  { id = "df021288-bdef-4463-88db-98f22de89214", type = "Role", value = "User.Read.All" }
]
```

### ❌ Mistake 3: Mixing Auth Scopes
```python
# WRONG: Using Graph token for ARM API
token = credential.get_token("https://graph.microsoft.com/.default")
requests.get(
    "https://management.azure.com/...",  # Different API!
    headers={"Authorization": f"Bearer {token.token}"}
)
```

**✅ Correct:**
```python
# Use correct scope for each API
graph_token = credential.get_token("https://graph.microsoft.com/.default")
arm_token = credential.get_token("https://management.azure.com/.default")
```

## 📚 Quick Reference

| I need to... | Use API | Auth Scope | Permission Example |
|-------------|---------|------------|-------------------|
| Read user profiles | Microsoft Graph | `https://graph.microsoft.com/.default` | `User.Read.All` |
| Send emails | Microsoft Graph | `https://graph.microsoft.com/.default` | `Mail.Send` |
| Deploy VMs | ARM | `https://management.azure.com/.default` | RBAC: `Contributor` |
| Access Storage blobs | Storage API | N/A (use RBAC) | RBAC: `Storage Blob Data Reader` |
| Read Key Vault secrets | Key Vault API | N/A (use access policy) | Access Policy: `Get`, `List` |
| Call my backend | Custom API | `api://backend-id/.default` | Custom scope: `Tasks.Read` |

## 🎯 Decision Checklist

Before requesting permissions, ask:

1. ☑️ **Is this Microsoft 365 data?** → Use Graph
2. ☑️ **Is this Azure infrastructure?** → Use ARM + RBAC
3. ☑️ **Is this an Azure service with SDK?** → Use resource API + RBAC
4. ☑️ **Is this my own API?** → Use custom scopes
5. ☑️ **Do I really need this permission?** → Principle of least privilege
6. ☑️ **Can I use delegated instead of application?** → Prefer delegated when possible

## 📖 Additional Resources

- [Microsoft Graph Permissions](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Azure RBAC Built-in Roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles)
- [Azure AD App Permissions Best Practices](https://learn.microsoft.com/en-us/azure/active-directory/develop/secure-least-privileged-access)
- [Managed Identity for Azure Resources](https://learn.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
