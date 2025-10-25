# Terraform State Access with Dynamic IP

## The Problem

Your Terraform state file is stored in Azure Storage Account `tfstate20251013`, which has firewall rules that only allow specific IPs. When your IP changes, Terraform cannot access the state file, causing operations to fail.

## Quick Solution - Use the Wrapper Scripts

I've created wrapper scripts that automatically update your IP before running Terraform:

### **Bash (Linux/macOS/Git Bash on Windows)**

```bash
cd /c/Repos/fictional-octo-system/terraform

# Make scripts executable
chmod +x update-ip.sh tf.sh

# Use the wrapper instead of terraform directly
./tf.sh init
./tf.sh plan
./tf.sh apply
./tf.sh destroy
```

### **PowerShell (Windows)**

```powershell
cd C:\Repos\fictional-octo-system\terraform

# Use the wrapper instead of terraform directly
.\tf.ps1 init
.\tf.ps1 plan
.\tf.ps1 apply
.\tf.ps1 destroy
```

The wrapper automatically:
1. Gets your current IP
2. Adds it to storage account firewall
3. Runs your Terraform command
4. Works with any Terraform command

---

## Alternative Solutions

### **Option 2: Service Principal with Storage Key Access**

Use Azure AD authentication instead of IP whitelisting:

```bash
# Set environment variables for Terraform backend authentication
export ARM_CLIENT_ID="<service-principal-app-id>"
export ARM_CLIENT_SECRET="<service-principal-password>"
export ARM_TENANT_ID="<tenant-id>"
export ARM_SUBSCRIPTION_ID="<subscription-id>"

# Grant Service Principal access to storage
az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $ARM_CLIENT_ID \
  --scope /subscriptions/$ARM_SUBSCRIPTION_ID/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstate20251013

# Then configure storage to allow Azure AD authentication
az storage account update \
  --name tfstate20251013 \
  --resource-group rg-tfstate \
  --allow-blob-public-access false \
  --default-action Allow
```

Update `backend.tf`:
```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfstate20251013"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    use_azuread_auth     = true  # Use Azure AD instead of storage keys
  }
}
```

**Pros**: No IP management, works from anywhere
**Cons**: Need to manage service principal credentials

---

### **Option 3: Terraform Cloud (Free Tier)**

Use Terraform Cloud to manage state remotely:

1. Create free account at https://app.terraform.io
2. Create organization and workspace
3. Update backend:

```hcl
terraform {
  cloud {
    organization = "your-org-name"
    workspaces {
      name = "fictional-octo-system"
    }
  }
}
```

4. Migrate state:
```bash
terraform init -migrate-state
```

**Pros**: No IP issues, state versioning, team collaboration
**Cons**: State stored outside your Azure account

---

### **Option 4: GitHub Actions / Azure DevOps**

Run Terraform from CI/CD pipelines:

**GitHub Actions** (using managed identity):
```yaml
name: Terraform Deploy

on:
  push:
    branches: [main]
  pull_request:

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Azure Login
        uses: azure/login@v1
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
      
      - name: Terraform Init
        run: terraform init
        working-directory: ./terraform
      
      - name: Terraform Plan
        run: terraform plan
        working-directory: ./terraform
      
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        run: terraform apply -auto-approve
        working-directory: ./terraform
```

**Pros**: Consistent IP from GitHub runners, no local IP issues
**Cons**: Can't run quick local tests

---

## Recommended Workflow

### **For Daily Work: Use Wrapper Scripts**

```bash
# In your terraform directory
./tf.sh plan    # Automatically updates IP and runs plan
./tf.sh apply   # Automatically updates IP and runs apply
```

### **For Production: Consider Alternatives**

1. **Small teams**: Terraform Cloud (free tier)
2. **Enterprise**: Azure DevOps with managed identity
3. **Security-critical**: Service Principal with Azure AD auth

---

## Manual IP Management

If you don't want to use the wrapper scripts:

### **Update IP Manually**

```bash
# Get your current IP
MY_IP=$(curl -s ifconfig.me)

# Add to storage account
az storage account network-rule add \
  --account-name tfstate20251013 \
  --resource-group rg-tfstate \
  --ip-address $MY_IP

# Now run terraform
terraform plan
```

### **Clean Up Old IPs**

```bash
# List current IPs
az storage account show \
  --name tfstate20251013 \
  --resource-group rg-tfstate \
  --query "networkRuleSet.ipRules[].value" \
  --output table

# Remove old IP
az storage account network-rule remove \
  --account-name tfstate20251013 \
  --resource-group rg-tfstate \
  --ip-address <old-ip>
```

---

## Troubleshooting

### Error: "Failed to get existing workspaces: storage: service returned error: StatusCode=403"

**Cause**: Your current IP is not whitelisted

**Solution**:
```bash
# Run the update script
./update-ip.sh  # or update-ip.ps1

# Then try terraform again
terraform init
```

### Error: "Error acquiring the state lock"

**Cause**: Another Terraform operation is in progress or crashed

**Solution**:
```bash
# Force unlock (use with caution!)
terraform force-unlock <lock-id>
```

### Error: "unauthorized: failed to authenticate"

**Cause**: Not logged in to Azure

**Solution**:
```bash
az login
az account show  # Verify you're logged in
```

---

## Security Best Practices

### **Cleanup Old IPs Regularly**

Create a maintenance script:

```bash
#!/bin/bash
# cleanup-old-ips.sh

STORAGE_ACCOUNT="tfstate20251013"
RESOURCE_GROUP="rg-tfstate"
CURRENT_IP=$(curl -s ifconfig.me)

echo "Current IP: $CURRENT_IP"
echo ""
echo "All whitelisted IPs:"

az storage account show \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --query "networkRuleSet.ipRules[].value" \
  --output table

echo ""
read -p "Remove all IPs except current? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Get all IPs except current
    OLD_IPS=$(az storage account show \
      --name $STORAGE_ACCOUNT \
      --resource-group $RESOURCE_GROUP \
      --query "networkRuleSet.ipRules[?value!='$CURRENT_IP'].value" \
      --output tsv)
    
    for IP in $OLD_IPS; do
        echo "Removing $IP..."
        az storage account network-rule remove \
          --account-name $STORAGE_ACCOUNT \
          --resource-group $RESOURCE_GROUP \
          --ip-address $IP
    done
    
    echo "✅ Cleanup complete!"
fi
```

### **Monitor Access**

Enable diagnostic logs:

```bash
az monitor diagnostic-settings create \
  --resource /subscriptions/<sub-id>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstate20251013 \
  --name "StorageAccessLogs" \
  --logs '[{"category": "StorageRead", "enabled": true}, {"category": "StorageWrite", "enabled": true}]' \
  --workspace <log-analytics-workspace-id>
```

---

## Quick Reference

| Scenario | Solution | Command |
|----------|----------|---------|
| **Quick local deployment** | Use wrapper script | `./tf.sh apply` |
| **Manual IP update** | Update then deploy | `./update-ip.sh && terraform apply` |
| **CI/CD pipeline** | Use GitHub Actions | See GitHub Actions example |
| **Multiple locations** | Service Principal + Azure AD | Set `use_azuread_auth = true` |
| **Team collaboration** | Terraform Cloud | Migrate to app.terraform.io |
| **IP cleanup** | Remove old IPs | `az storage account network-rule remove` |

---

## Next Steps

1. **Try the wrapper script**:
   ```bash
   cd /c/Repos/fictional-octo-system/terraform
   chmod +x tf.sh update-ip.sh
   ./tf.sh plan
   ```

2. **Set up aliases** (optional):
   ```bash
   # Add to ~/.bashrc or ~/.zshrc
   alias tf='./tf.sh'
   
   # Then just use:
   tf plan
   tf apply
   ```

3. **Consider long-term solution**:
   - For personal projects: Keep using wrapper scripts
   - For team projects: Move to Terraform Cloud or Azure DevOps
   - For production: Use Service Principal with Azure AD auth

The wrapper scripts are the **quickest solution** that requires zero infrastructure changes and works immediately!
