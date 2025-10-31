# 🚀 Quick Start Guide

> *"Get your Key Vault running in 5 minutes (or your money back)"* ⏱️

## Option 1: Basic Key Vault (Development)

```bash
# 1. Clone and navigate
cd deployments/azure/key-vault

# 2. Create your config
cat > terraform.tfvars <<EOF
key_vault_name         = "kv-dev-$(whoami)-001"
resource_group_name    = "rg-keyvault-dev"
create_resource_group  = true
location               = "swedencentral"

# Less restrictive for dev
purge_protection_enabled      = false
network_acls_default_action   = "Allow"
assign_deployer_admin         = true

tags = {
  Environment = "development"
  ManagedBy   = "terraform"
}
EOF

# 3. Deploy
terraform init
terraform apply -auto-approve

# 4. Test it
export KV_NAME=$(terraform output -raw key_vault_name)
az keyvault secret set --vault-name $KV_NAME --name test --value "hello"
az keyvault secret show --vault-name $KV_NAME --name test --query value -o tsv
```

## Option 2: Production Key Vault

```bash
# 1. Get your object ID
MY_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
echo "Your Object ID: $MY_OBJECT_ID"

# 2. Create your config
cat > terraform.tfvars <<EOF
key_vault_name         = "kv-prod-myapp-001"
resource_group_name    = "rg-keyvault-prod"
create_resource_group  = true
location               = "swedencentral"
sku_name               = "standard"

# Production security
purge_protection_enabled       = true
soft_delete_retention_days     = 90
network_acls_default_action    = "Deny"
allowed_ip_addresses           = ["$(curl -s ifconfig.me)/32"]

# RBAC
assign_deployer_admin = true

tags = {
  Environment = "production"
  ManagedBy   = "terraform"
  CostCenter  = "engineering"
}
EOF

# 3. Deploy
terraform init
terraform plan  # Review before applying!
terraform apply

# 4. Wait for RBAC propagation (2-5 minutes)
echo "Waiting for RBAC to propagate..."
sleep 120

# 5. Test
export KV_NAME=$(terraform output -raw key_vault_name)
az keyvault secret set --vault-name $KV_NAME --name db-password --value "SuperSecret123!"
```

## Option 3: Private Key Vault (High Security)

```bash
# Prerequisites: You need a VNet and subnet first

# 1. Get network details
VNET_RG="rg-network-prod"
VNET_NAME="vnet-prod"
SUBNET_NAME="subnet-private-endpoints"

SUBNET_ID=$(az network vnet subnet show \
  --resource-group $VNET_RG \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query id -o tsv)

# 2. Create config
cat > terraform.tfvars <<EOF
key_vault_name         = "kv-private-prod-001"
resource_group_name    = "rg-keyvault-prod"
create_resource_group  = true
location               = "swedencentral"

# No public access!
public_network_access_enabled = false
network_acls_default_action   = "Deny"
network_acls_bypass           = "AzureServices"

# Private endpoint
enable_private_endpoint    = true
private_endpoint_subnet_id = "$SUBNET_ID"

# Production security
purge_protection_enabled   = true
soft_delete_retention_days = 90
assign_deployer_admin      = true

tags = {
  Environment = "production"
  Security    = "high"
}
EOF

# 3. Deploy
terraform init
terraform apply
```

## Common Post-Deployment Tasks

### Grant Access to an Application

```bash
# Get your Key Vault scope
KV_SCOPE=$(terraform output -raw key_vault_id)

# Get your app's managed identity
APP_PRINCIPAL_ID=$(az webapp identity show \
  --name my-app \
  --resource-group rg-apps \
  --query principalId -o tsv)

# Grant Secrets User role
az role assignment create \
  --role "Key Vault Secrets User" \
  --assignee $APP_PRINCIPAL_ID \
  --scope $KV_SCOPE

echo "✅ Access granted! Wait 2-5 minutes for propagation."
```

### Add a Secret

```bash
KV_NAME=$(terraform output -raw key_vault_name)

# Simple secret
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "api-key" \
  --value "sk-1234567890"

# Multi-line secret (like JSON)
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "config" \
  --value @config.json

# Secret with expiration
az keyvault secret set \
  --vault-name $KV_NAME \
  --name "temp-token" \
  --value "token123" \
  --expires "2025-12-31T23:59:59Z"
```

### Verify RBAC Configuration

```bash
KV_NAME=$(terraform output -raw key_vault_name)

# Check if RBAC is enabled
az keyvault show --name $KV_NAME --query enableRbacAuthorization
# Should output: true

# List all role assignments
az role assignment list --scope $(terraform output -raw key_vault_id) --output table
```

## Troubleshooting

### ❌ "Access Denied" After Deployment

**Cause**: RBAC propagation delay (2-5 minutes)

**Fix**: Wait and retry
```bash
sleep 180
az keyvault secret set --vault-name $KV_NAME --name test --value "retry"
```

### ❌ "Vault Name Already Exists"

**Cause**: Name is taken or soft-deleted

**Fix**: Check for soft-deleted vaults
```bash
# List deleted vaults
az keyvault list-deleted --query "[?name=='kv-myapp-prod']"

# Purge if you own it
az keyvault purge --name kv-myapp-prod

# Or recover it
az keyvault recover --name kv-myapp-prod
```

### ❌ "Network Access Denied"

**Cause**: Your IP is not in allowed list

**Fix**: Add your current IP
```bash
MY_IP=$(curl -s ifconfig.me)
az keyvault network-rule add \
  --name $KV_NAME \
  --ip-address $MY_IP/32
```

## Next Steps

1. **Add Monitoring**: Check diagnostic logs in Azure Portal
2. **Configure Alerts**: Set up alerts for unauthorized access
3. **Document Access**: Keep a list of who has what role
4. **Regular Audits**: Review role assignments monthly
5. **Rotate Secrets**: Implement secret rotation for long-lived credentials

## Useful Commands Cheat Sheet

```bash
# Get vault info
az keyvault show --name $KV_NAME

# List all secrets (names only)
az keyvault secret list --vault-name $KV_NAME --query "[].name" -o tsv

# Backup a secret
az keyvault secret backup \
  --vault-name $KV_NAME \
  --name my-secret \
  --file secret-backup.blob

# Restore a secret
az keyvault secret restore \
  --vault-name $KV_NAME \
  --file secret-backup.blob

# Delete a secret (soft delete)
az keyvault secret delete --vault-name $KV_NAME --name my-secret

# Recover deleted secret
az keyvault secret recover --vault-name $KV_NAME --name my-secret

# View diagnostic logs
az monitor diagnostic-settings show \
  --resource $(terraform output -raw key_vault_id) \
  --name "${KV_NAME}-diagnostics"
```

---

> *"Remember: With great Key Vault comes great responsibility"* 🕷️🔑
