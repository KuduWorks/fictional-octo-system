# Azure AD App Registration Automation

> *"Because manually clicking through the Azure Portal is so 2015"* 🎭

This Terraform module automates the creation and management of Azure AD (Entra ID) application registrations, service principals, and client secret rotation. It demonstrates how to wire workloads into Entra ID with best practices for authentication and authorization. No more copying GUIDs into sticky notes or storing secrets in a text file called `definitely-not-secrets.txt`.

## 🎯 Overview

This module handles the complete lifecycle of Azure AD applications (so you don't have to):

- **App Registration**: Create and configure Azure AD applications
- **Service Principals**: Establish service identities for workloads
- **Secret Rotation**: Automatic client secret rotation with configurable intervals
- **API Permissions**: Manage Microsoft Graph and custom API permissions
- **Federated Credentials**: Passwordless authentication via OIDC (GitHub Actions, Kubernetes)
- **Key Vault Integration**: Secure storage of credentials
- **Admin Consent**: Automated permission grants (when authorized)

## 📋 Prerequisites

- Terraform >= 1.3.0
- Azure CLI authenticated with appropriate permissions (aka: you've survived `az login`)
- Azure AD permissions:
  - `Application.ReadWrite.All` (to create apps)
  - `AppRoleAssignment.ReadWrite.All` (for admin consent)
  - `Directory.Read.All` (to read directory objects)
- ☕ Coffee (recommended but not technically required)
- 🧘 Patience for Azure AD permission propagation delays

## 🚀 Quick Start

### 1. Basic Application Registration

```hcl
module "basic_app" {
  source = "./app-registration"

  app_display_name = "my-backend-api"
  sign_in_audience = "AzureADMyOrg"
  
  # Basic Microsoft Graph permissions
  graph_permissions = [
    {
      id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"
      type  = "Scope"  # Delegated permission
      value = "User.Read"
    }
  ]

  secret_rotation_days = 90
  tags                 = ["Environment:Dev", "ManagedByTerraform"]
}

output "client_id" {
  value = module.basic_app.application_id
}

output "client_secret" {
  value     = module.basic_app.client_secret
  sensitive = true
}
```

### 2. Deploy the Module

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply

# Retrieve the client secret
terraform output -raw client_secret
```

### 3. Use the Credentials

```bash
# Export for use in applications
export AZURE_CLIENT_ID=$(terraform output -raw application_id)
export AZURE_CLIENT_SECRET=$(terraform output -raw client_secret)
export AZURE_TENANT_ID=$(terraform output -raw tenant_id)
```

## 🔐 Permission Scopes: Graph vs. Resource-Specific

### When to Use Microsoft Graph Permissions

Use **Microsoft Graph** API permissions when your application needs to:

#### ✅ User and Group Management
- Read user profiles (`User.Read`, `User.Read.All`)
- Manage users and groups (`User.ReadWrite.All`, `Group.ReadWrite.All`)
- Access organizational directory data (`Directory.Read.All`)

#### ✅ Email and Calendar
- Read emails (`Mail.Read`)
- Send emails (`Mail.Send`)
- Manage calendars (`Calendars.ReadWrite`)

#### ✅ Teams and SharePoint
- Access Teams data (`Team.ReadBasic.All`)
- Read SharePoint sites (`Sites.Read.All`)

#### ✅ Identity and Security
- Read audit logs (`AuditLog.Read.All`)
- Manage conditional access policies (`Policy.ReadWrite.ConditionalAccess`)

**Example: Application needing user data**
```hcl
graph_permissions = [
  {
    id    = "df021288-bdef-4463-88db-98f22de89214"  # User.Read.All
    type  = "Role"                                   # Application permission
    value = "User.Read.All"
  },
  {
    id    = "5b567255-7703-4780-807c-7be8301ae99b"  # Group.Read.All
    type  = "Role"
    value = "Group.Read.All"
  }
]

grant_admin_consent = true  # Required for application permissions
```

### When to Use Resource-Specific Permissions

Use **resource-specific** permissions when your application needs to:

#### ✅ Azure Resource Management
- Manage Azure resources (VMs, storage, databases)
- Deploy infrastructure
- Monitor resources

**Use Azure Resource Manager (ARM) API** instead of Graph:
```hcl
arm_permissions = [
  {
    id    = "41094075-9dad-400e-a0bd-54e686782033"  # user_impersonation
    type  = "Scope"
    value = "user_impersonation"
  }
]
```

#### ✅ Custom APIs (Your Own Services)
- Access your own backend APIs
- Call internal microservices
- Service-to-service authentication

```hcl
custom_api_permissions = [
  {
    resource_app_id = "12345678-1234-1234-1234-123456789abc"  # Your API's App ID
    permissions = [
      {
        id   = "abcd1234-5678-90ab-cdef-1234567890ab"
        type = "Scope"  # Delegated permission
      }
    ]
  }
]
```

#### ✅ Azure Services with Direct APIs
- Azure Storage (use Storage Account keys or SAS tokens)
- Azure Key Vault (use Managed Identity)
- Azure SQL Database (use Managed Identity or SQL auth)
- Cosmos DB (use account keys or RBAC)

### Decision Matrix

| Scenario | Use Microsoft Graph | Use Resource-Specific |
|----------|-------------------|----------------------|
| Read user profile information | ✅ Yes (`User.Read`) | ❌ No |
| Send emails via Outlook | ✅ Yes (`Mail.Send`) | ❌ No |
| Deploy Azure VMs | ❌ No | ✅ Yes (ARM API) |
| Access Azure Storage blobs | ❌ No | ✅ Yes (Storage API) |
| Call your custom backend API | ❌ No | ✅ Yes (Custom API) |
| Manage Azure AD users | ✅ Yes (`User.ReadWrite.All`) | ❌ No |
| Read audit logs | ✅ Yes (`AuditLog.Read.All`) | ❌ No |
| Manage Azure Key Vault secrets | ❌ No | ✅ Yes (RBAC/Access Policies) |

## 📚 Common Use Cases

### Use Case 1: Backend API with User Sign-In

Application that authenticates users and reads their profile:

```hcl
module "web_app" {
  source = "./app-registration"

  app_display_name = "customer-portal"
  sign_in_audience = "AzureADMyOrg"
  
  redirect_uris = [
    "https://portal.example.com/auth/callback"
  ]

  # Delegated permissions (user context)
  graph_permissions = [
    {
      id    = "e1fe6dd8-ba31-4d61-89e7-88639da4683d"  # User.Read
      type  = "Scope"
      value = "User.Read"
    },
    {
      id    = "64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0"  # email
      type  = "Scope"
      value = "email"
    },
    {
      id    = "14dad69e-099b-42c9-810b-d002981feec1"  # profile
      type  = "Scope"
      value = "profile"
    }
  ]

  secret_rotation_days = 90
  store_in_key_vault   = true
  key_vault_id         = azurerm_key_vault.main.id
}
```

### Use Case 2: Background Service with Application Permissions

Daemon application that runs without user interaction:

```hcl
module "background_service" {
  source = "./app-registration"

  app_display_name = "user-sync-service"
  sign_in_audience = "AzureADMyOrg"

  # Application permissions (app-only context)
  graph_permissions = [
    {
      id    = "df021288-bdef-4463-88db-98f22de89214"  # User.Read.All
      type  = "Role"                                   # Application permission
      value = "User.Read.All"
    },
    {
      id    = "5b567255-7703-4780-807c-7be8301ae99b"  # Group.Read.All
      type  = "Role"
      value = "Group.Read.All"
    }
  ]

  # Admin consent required for application permissions
  grant_admin_consent = true

  secret_rotation_days = 90
  notification_emails  = ["ops-team@example.com"]
  
  store_in_key_vault = true
  key_vault_id       = azurerm_key_vault.main.id
}
```

### Use Case 3: GitHub Actions with Passwordless Auth (OIDC)

CI/CD pipeline using federated identity credentials (recommended):

```hcl
module "github_actions_app" {
  source = "./app-registration"

  app_display_name = "github-actions-deployer"
  sign_in_audience = "AzureADMyOrg"

  # No client secret needed - using OIDC!
  enable_github_oidc = true
  github_org         = "my-org"
  github_repo        = "my-app"
  github_branch      = "main"

  # Azure Resource Manager permissions for deployment
  arm_permissions = [
    {
      id    = "41094075-9dad-400e-a0bd-54e686782033"
      type  = "Scope"
      value = "user_impersonation"
    }
  ]

  secret_rotation_days = 90  # Backup secret, prefer OIDC
}
```

**GitHub Actions workflow:**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Azure

on:
  push:
    branches: [main]

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login (OIDC)
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy resources
        run: |
          az group create --name my-rg --location eastus
          az deployment group create --resource-group my-rg --template-file main.bicep
```

### Use Case 4: Kubernetes Workload Identity (AKS)

Application running in AKS accessing Azure resources:

```hcl
module "aks_workload" {
  source = "./app-registration"

  app_display_name = "aks-app-identity"
  sign_in_audience = "AzureADMyOrg"

  enable_kubernetes_oidc     = true
  kubernetes_issuer_url      = "https://oidc.prod-aks.azure.com/00000000-..."
  kubernetes_namespace       = "production"
  kubernetes_service_account = "app-service-account"

  # No Graph permissions - accessing Azure resources only
  secret_rotation_days = 90
}

# Grant RBAC roles on Azure resources
resource "azurerm_role_assignment" "storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.aks_workload.service_principal_id
}
```

### Use Case 5: Multi-Tier Application

API exposing its own scopes to a frontend:

```hcl
# Backend API
module "backend_api" {
  source = "./app-registration"

  app_display_name = "backend-api"
  
  # Expose API with custom scopes
  expose_api = true
  api_scopes = [
    {
      id                         = "12345678-1234-1234-1234-123456789abc"
      value                      = "Tasks.Read"
      admin_consent_display_name = "Read tasks"
      admin_consent_description  = "Allows the app to read tasks"
      user_consent_display_name  = "Read your tasks"
      user_consent_description   = "Allows the app to read your tasks"
    },
    {
      id                         = "87654321-4321-4321-4321-cba987654321"
      value                      = "Tasks.Write"
      admin_consent_display_name = "Write tasks"
      admin_consent_description  = "Allows the app to create and update tasks"
      user_consent_display_name  = "Manage your tasks"
      user_consent_description   = "Allows the app to create and update your tasks"
    }
  ]

  secret_rotation_days = 90
}

# Frontend application
module "frontend_app" {
  source = "./app-registration"

  app_display_name = "frontend-spa"
  sign_in_audience = "AzureADMyOrg"
  
  redirect_uris = ["https://app.example.com/auth/callback"]

  # Permission to call backend API
  custom_api_permissions = [
    {
      resource_app_id = module.backend_api.application_id
      permissions = [
        {
          id   = "12345678-1234-1234-1234-123456789abc"  # Tasks.Read
          type = "Scope"
        },
        {
          id   = "87654321-4321-4321-4321-cba987654321"  # Tasks.Write
          type = "Scope"
        }
      ]
    }
  ]

  secret_rotation_days = 90
}
```

## 🔄 Secret Rotation Strategy

> *"Passwords are like underwear: change them regularly, don't share them, and don't leave them lying around."* 🔐

### Automatic Rotation

The module uses `time_rotating` resource to automatically rotate secrets (because we all know you'll forget):

```hcl
secret_rotation_days = 90  # Recommended: 90-180 days (or 7 if your org is paranoid)
```

**How it works:**
1. Terraform tracks the rotation schedule (unlike your memory)
2. On next `terraform apply` after rotation period, a new secret is created
3. Old secret remains valid until its expiration date (grace period for when you're on vacation)
4. Update your applications with the new secret before old one expires (⚠️ Set a calendar reminder!)

### Manual Secret Rotation

Force immediate rotation:

```bash
# Taint the rotation timer
terraform taint 'time_rotating.secret_rotation'

# Apply to generate new secret
terraform apply
```

### Best Practices

1. **Regular Rotation**: 90 days for most applications, 180 days maximum
2. **Overlap Period**: New secret created before old expires (grace period)
3. **Key Vault Storage**: Always store secrets in Key Vault
4. **Monitoring**: Set up alerts for expiring secrets
5. **Certificate Preferred**: Use certificate auth for high-security scenarios

### Certificate-Based Authentication (Most Secure)

```hcl
module "cert_app" {
  source = "./app-registration"

  app_display_name      = "secure-service"
  use_certificate_auth  = true
  certificate_value     = file("cert.pem")  # Public key only
  certificate_end_date  = "2025-12-31T23:59:59Z"
  
  secret_rotation_days = 90  # Backup secret
}
```

## 🔍 Finding Permission IDs

> *"Because memorizing 128-bit GUIDs is totally a normal human skill"* 🧠

### Method 1: Microsoft Graph API (For the Cool Kids)

```bash
# List all available permissions
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "oauth2PermissionScopes[].{id:id, value:value, type:'Scope'}" \
  --output table

# List application permissions
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "appRoles[].{id:id, value:value, type:'Role'}" \
  --output table
```

### Method 2: Azure Portal (For Those Who Like Clicking)

1. Navigate to **Azure AD** → **App registrations**
2. Open any app → **API permissions** → **Add a permission**
3. Select **Microsoft Graph**
4. Find the permission and click "Copy" next to the ID
5. Try not to get distracted by the other 47 tabs you have open 🌐

### Common Permission IDs

| Permission Name | ID | Type | Description |
|----------------|-----|------|-------------|
| User.Read | e1fe6dd8-ba31-4d61-89e7-88639da4683d | Scope | Sign in and read user profile |
| User.Read.All | df021288-bdef-4463-88db-98f22de89214 | Role | Read all users' profiles |
| User.ReadWrite.All | 741f803b-c850-494e-b5df-cde7c675a1ca | Role | Read and write all users |
| Directory.Read.All | 7ab1d382-f21e-4acd-a863-ba3e13f7da61 | Role | Read directory data |
| Mail.Read | 810c84a8-4a9e-49e6-bf7d-12d183f40d01 | Scope | Read user mail |
| Mail.Send | e383f46e-2787-4529-855e-0e479a3ffac0 | Scope | Send mail as user |

**Legend:**
- **Scope** = Delegated permission (acts on behalf of user)
- **Role** = Application permission (acts as the app itself)

## 🏷️ Understanding Tags in Azure AD and Azure Resources

This module uses three different types of tags, each serving a distinct purpose. Understanding the difference is crucial for proper configuration.

### Azure AD Application Tags

**What they are**: Simple string labels for categorizing applications in Azure AD

**Format**: Set of strings (not key-value pairs!)

```hcl
# In main.tf line 134
resource "azuread_application" "app" {
  tags = toset(["Production", "ManagedByTerraform", "CustomerFacing"])
}
```

**Purpose**:
- Categorize applications in Azure AD portal
- Filter and search apps
- Custom organizational labels

**Where to see them**: Azure Portal → App Registrations → Your App → Overview

---

### Azure AD Service Principal Feature Tags

**What they are**: Boolean flags that control the **behavior and type** of the service principal

**Format**: Boolean properties (not user-defined!)

```hcl
# In main.tf around line 148
resource "azuread_service_principal" "app_sp" {
  feature_tags {
    enterprise = false  # Is this an Enterprise Application?
    gallery    = false  # Is this from the Azure AD Gallery?
    hide       = false  # Hide from user portals?
    custom_single_sign_on = false  # Custom SSO configuration?
  }
}
```

**Purpose**:
- **enterprise**: Makes the app appear as an "Enterprise Application"
- **gallery**: Indicates if it's a pre-integrated gallery app
- **hide**: Hides the app from MyApps portal
- **custom_single_sign_on**: Enables custom SSO features

**Where to see them**: Azure Portal → Enterprise Applications → Your App → Properties

⚠️ **Important**: You cannot use both `tags` and `feature_tags` on a service principal - they conflict!

---

### Azure Resource Tags

**What they are**: Key-value metadata for Azure infrastructure resources

**Format**: Map of strings (key-value pairs)

```hcl
# In main.tf lines 238, 248, 263 (Key Vault secrets)
resource "azurerm_key_vault_secret" "client_id" {
  tags = {
    ManagedBy   = "Terraform"
    Environment = "Production"
    CostCenter  = "12345"
    Owner       = "team@company.com"
    Project     = "MyApp"
  }
}
```

**Purpose**:
- **Cost tracking**: Group resources for billing reports
- **Organization**: Categorize by environment, department, project
- **Automation**: Target resources in scripts based on tags
- **Compliance**: Track ownership and requirements

**Where to see them**: Azure Portal → Any Resource → Tags blade

---

### Comparison Table

| Feature | Application Tags | Feature Tags | Resource Tags |
|---------|-----------------|--------------|---------------|
| **Used On** | `azuread_application` | `azuread_service_principal` | Azure resources (`azurerm_*`) |
| **Format** | Set of strings | Boolean flags | Key-value pairs |
| **Example** | `["Production"]` | `enterprise = true` | `{env = "prod"}` |
| **Purpose** | Organize apps | Control behavior | Cost tracking, automation |
| **User-Defined** | ✅ Yes | ❌ No (fixed options) | ✅ Yes |
| **Max Count** | Unlimited | 4 fixed flags | 50 per resource |

### Configuration in This Module

```hcl
# Your var.tags should be a map for Azure resources
variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
# Application tags are derived from tag values
resource "azuread_application" "app" {
  tags = toset(values(var.tags))  # Converts to ["Terraform"]
}

# Feature tags control service principal behavior
resource "azuread_service_principal" "app_sp" {
  feature_tags {
    enterprise = var.enable_enterprise_features
    gallery    = var.enable_gallery_features
  }
}

# Resource tags use the map directly
resource "azurerm_key_vault_secret" "client_id" {
  tags = var.tags  # Uses {ManagedBy = "Terraform"}
}
```

## 📖 Additional Resources

- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Azure AD App Registration Best Practices](https://learn.microsoft.com/en-us/azure/active-directory/develop/security-best-practices-for-app-registration)
- [Workload Identity Federation](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation)
- [Certificate Credentials](https://learn.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal#option-1-recommended-upload-a-certificate)
- [Azure Resource Tagging Best Practices](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging)

## 🔒 Security Best Practices

> *"Because 'Everyone is Owner' is not a valid security model"* 🛡️

1. **Principle of Least Privilege**: Only request necessary permissions  
   *(Not "Permission of Most Convenience")*

2. **Use Application Permissions Sparingly**: Prefer delegated when possible  
   *(Your app probably doesn't need to be God Mode)*

3. **Federated Credentials**: Use OIDC instead of secrets when available  
   *(Passwords are so 2010. We're in the passwordless future now!)*

4. **Key Vault Storage**: Always store secrets in Key Vault  
   *(Not in `secrets.txt`, not in environment variables you forgot about, and definitely not in that Slack message from 2019)*

5. **Regular Rotation**: Rotate secrets every 90-180 days  
   *(Or 7 days if your Azure AD admin is particularly paranoid... they're probably right)*

6. **Admin Consent Tracking**: Document why each permission is needed  
   *(Future you will thank present you when the auditor asks)*

7. **Monitoring**: Set up alerts for permission changes and secret access  
   *(So you know when things go wrong before your manager does)* 📊

## 🤝 Contributing

> *"Pull requests welcome! Bug reports... also welcome, but less exciting"* 😅

Contributions welcome! Please ensure:
- Terraform code follows HashiCorp style guidelines *(yes, we run `terraform fmt`)*
- All variables have descriptions and validation rules *(because "does the thing" is not a valid description)*
- Examples are tested and working *(on your machine AND someone else's)*
- Documentation is updated *(code without docs is like a map without labels - technically functional but wildly frustrating)*

**Pro tip**: If your PR includes a meme that explains the fix, it gets priority review 🚀

## 📄 License

This module is part of the fictional-octo-system repository and follows the same MIT License.
