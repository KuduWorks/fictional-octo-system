# Azure AD App Registration - Quick Reference Card

## 🚀 Quick Start Commands

```bash
# Navigate to directory
cd deployments/azure/app-registration

# Initialize Terraform
terraform init

# Create configuration
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars

# Plan deployment
terraform plan

# Deploy app registration
terraform apply

# Get client secret
terraform output -raw client_secret

# Destroy app registration
terraform destroy
```

## 🔑 Common Permission IDs

### User Permissions
| Permission | ID | Type |
|-----------|-----|------|
| User.Read | `e1fe6dd8-ba31-4d61-89e7-88639da4683d` | Scope |
| User.Read.All | `df021288-bdef-4463-88db-98f22de89214` | Role |
| User.ReadWrite.All | `741f803b-c850-494e-b5df-cde7c675a1ca` | Role |

### Group Permissions
| Permission | ID | Type |
|-----------|-----|------|
| Group.Read.All | `5b567255-7703-4780-807c-7be8301ae99b` | Role |
| Group.ReadWrite.All | `62a82d76-70ea-41e2-9197-370581804d09` | Role |

### Mail Permissions
| Permission | ID | Type |
|-----------|-----|------|
| Mail.Read | `810c84a8-4a9e-49e6-bf7d-12d183f40d01` | Scope |
| Mail.Send | `e383f46e-2787-4529-855e-0e479a3ffac0` | Scope |

### Directory Permissions
| Permission | ID | Type |
|-----------|-----|------|
| Directory.Read.All | `7ab1d382-f21e-4acd-a863-ba3e13f7da61` | Role |
| Directory.ReadWrite.All | `19dbc75e-c2e2-444c-a770-ec69d8559fc7` | Role |

### Audit & Security
| Permission | ID | Type |
|-----------|-----|------|
| AuditLog.Read.All | `b0afded3-3588-46d8-8b3d-9842eff778da` | Role |

### Profile Scopes
| Permission | ID | Type |
|-----------|-----|------|
| email | `64a6cdd6-aab1-4aaf-94b8-3cc8405e90d0` | Scope |
| profile | `14dad69e-099b-42c9-810b-d002981feec1` | Scope |
| openid | `37f7f235-527c-4136-accd-4a02d197296e` | Scope |

## 🎯 Permission Types

| Type | Description | Consent | Use Case |
|------|-------------|---------|----------|
| **Scope** | Delegated (on behalf of user) | User or Admin | Web apps, user context |
| **Role** | Application (app itself) | Admin only | Background services, daemons |

## 📝 Terraform Snippet Templates

### Basic App with User Sign-In
```hcl
module "app" {
  source = "./app-registration"
  
  app_display_name = "my-app"
  redirect_uris    = ["https://localhost:3000/callback"]
  
  graph_permissions = [
    { id = "e1fe6dd8-ba31-4d61-89e7-88639da4683d", type = "Scope", value = "User.Read" }
  ]
  
  secret_rotation_days = 90
}
```

### Background Service
```hcl
module "service" {
  source = "./app-registration"
  
  app_display_name = "background-service"
  
  graph_permissions = [
    { id = "df021288-bdef-4463-88db-98f22de89214", type = "Role", value = "User.Read.All" }
  ]
  
  grant_admin_consent = true
  secret_rotation_days = 90
}
```

### GitHub Actions (Passwordless)
```hcl
module "github" {
  source = "./app-registration"
  
  app_display_name   = "github-deployer"
  enable_github_oidc = true
  github_org         = "my-org"
  github_repo        = "my-repo"
  
  arm_permissions = [
    { id = "41094075-9dad-400e-a0bd-54e686782033", type = "Scope", value = "user_impersonation" }
  ]
}
```

## 🔍 Finding Permission IDs

### Azure CLI
```bash
# Search for permissions
./find-permissions.sh

# Or manually:
az ad sp show --id 00000003-0000-0000-c000-000000000000 \
  --query "oauth2PermissionScopes[?contains(value, 'User')]" \
  --output table
```

### PowerShell
```powershell
Connect-MgGraph
$sp = Get-MgServicePrincipal -Filter "appId eq '00000003-0000-0000-c000-000000000000'"
$sp.Oauth2PermissionScopes | Where-Object { $_.Value -like "*User*" }
```

## 🌐 API Endpoints & Scopes

| API | Base URL | Auth Scope |
|-----|----------|------------|
| Microsoft Graph | `graph.microsoft.com` | `https://graph.microsoft.com/.default` |
| Azure RM | `management.azure.com` | `https://management.azure.com/.default` |
| Storage | `*.blob.core.windows.net` | RBAC (no scope) |
| Key Vault | `*.vault.azure.net` | RBAC (no scope) |
| SQL Database | `*.database.windows.net` | `https://database.windows.net/.default` |
| Custom API | Your domain | `api://your-app-id/.default` |

## 🔐 Authentication Patterns

### Client Credentials (Secret)
```python
from azure.identity import ClientSecretCredential

credential = ClientSecretCredential(
    tenant_id="...",
    client_id="...",
    client_secret="..."
)

token = credential.get_token("https://graph.microsoft.com/.default")
```

### Certificate-Based
```python
from azure.identity import CertificateCredential

credential = CertificateCredential(
    tenant_id="...",
    client_id="...",
    certificate_path="cert.pem"
)
```

### Federated OIDC (GitHub Actions)
```yaml
- uses: azure/login@v1
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## 📊 Secret Rotation Guidelines

| Environment | Rotation Frequency | Recommendation |
|-------------|-------------------|----------------|
| Development | 180 days | Longer rotation OK |
| Staging | 90 days | Balance security & ops |
| Production | 60-90 days | Microsoft recommended |
| High Security | 30-60 days | Maximum security |

## ⚠️ Common Issues & Solutions

### Issue: "Insufficient privileges to complete the operation"
**Solution:** Your account needs `Application.ReadWrite.All` permission or Global Admin role

### Issue: "Need admin consent for this permission"
**Solution:** Set `grant_admin_consent = true` or manually grant in Azure Portal

### Issue: "The service principal does not exist"
**Solution:** Wait a few seconds after creation, or set `depends_on` in Terraform

### Issue: "Token expired"
**Solution:** Rotate secret using `terraform taint time_rotating.secret_rotation && terraform apply`

## 🛠️ Useful Commands

```bash
# List all outputs
terraform output

# Get specific output
terraform output -raw application_id
terraform output -raw client_secret

# Format Terraform files
terraform fmt

# Validate configuration
terraform validate

# Show current state
terraform show

# Refresh state
terraform refresh

# Import existing app
terraform import azuread_application.app <object-id>
```

## 📚 Documentation Links

- 📖 [Full README](./README.md)
- 🔐 [Permissions Reference](./PERMISSIONS.md)
- 🎯 [Scope Decision Guide](./SCOPE_GUIDE.md)
- 💡 [Examples](./examples/)

## 🆘 Getting Help

```bash
# Check Azure CLI version
az --version

# Login to Azure
az login

# Check permissions
az ad signed-in-user show

# List subscriptions
az account list --output table

# Set subscription
az account set --subscription <subscription-id>
```

## 🔒 Security Checklist

- [ ] Store secrets in Key Vault (`store_in_key_vault = true`)
- [ ] Use certificate auth for production (`use_certificate_auth = true`)
- [ ] Prefer OIDC over secrets (`enable_github_oidc = true`)
- [ ] Request minimum permissions needed
- [ ] Enable secret rotation (90 days recommended)
- [ ] Add `terraform.tfvars` to `.gitignore`
- [ ] Document why each permission is needed
- [ ] Review permissions quarterly
- [ ] Monitor service principal usage
- [ ] Set up notification emails

---

**📌 Pro Tips:**
- Use `terraform plan -out=tfplan` before applying
- Always review changes before running `terraform apply`
- Keep Terraform state secure (use remote backend)
- Document custom permission IDs in comments
- Use modules for consistency across environments
- Test in dev before deploying to production

**Version:** 1.0.0  
**Last Updated:** October 2025  
**License:** MIT
