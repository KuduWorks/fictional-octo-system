# Storage Account Access Options

Your public IP changes often, but the state storage firewall is locked down. Use Terraform's `storage_access_method` to control access. Dynamic IP wrapper scripts are archived/disabled under `archive/dynamic-ip-legacy/` and should not be used.

## Recommended Defaults
- State account: tfstateprod20251215 in resource group rg-tfstate, container tfstate-prod
- Auth: Azure AD/OIDC (UAMI) with `use_azuread_auth = true` in the backend
- Preferred access: `storage_access_method = "managed_identity"` or `"private_endpoint"`

## Example terraform.tfvars
```hcl
state_resource_group_name  = "rg-tfstate"
state_storage_account_name = "tfstateprod20251215"
storage_access_method      = "managed_identity" # or "private_endpoint", or temporary "ip_whitelist"
allowed_ip_addresses       = ["203.0.113.10"]   # only when using ip_whitelist
```

## Option 1: Private Endpoint (Most Secure)
- No internet exposure; traffic stays on Azure backbone
- Requires VNet connectivity (Bastion/VM, VPN, or ExpressRoute)
- Set `storage_access_method = "private_endpoint"` and apply

## Option 2: Managed Identity (Best for Automation)
- Works for GitHub Actions, VMs, and other Azure resources
- Grant `Storage Blob Data Contributor` on the state account to the identity that runs Terraform
- No IP management required when Azure services bypass is allowed

## Option 3: Temporary IP Whitelist
- Use only while waiting for managed identity access
- Set `storage_access_method = "ip_whitelist"` and list current IPs in `allowed_ip_addresses`
- To add a new IP quickly:
```bash
az storage account network-rule add \
  --account-name tfstateprod20251215 \
  --resource-group rg-tfstate \
  --ip-address $(curl -s ifconfig.me)
```

## Option 4: SAS Token (Short-Term Access)
- Generate a time-limited SAS when you cannot change firewall rules
```bash
az storage account generate-sas \
  --account-name tfstateprod20251215 \
  --services b \
  --resource-types sco \
  --permissions rwdlac \
  --expiry $(date -u -d "30 days" '+%Y-%m-%dT%H:%MZ') \
  --https-only -o tsv
```
- Use with `AZURE_STORAGE_SAS_TOKEN` and `--auth-mode login`

## Option 5: Azure Cloud Shell
- Always authenticated; no IP restrictions
- Suitable for quick administration and emergency access

## Quick Commands
- List blobs via AAD: `az storage blob list --account-name tfstateprod20251215 --container-name tfstate-prod --auth-mode login`
- Check firewall rules: `az storage account show --name tfstateprod20251215 --resource-group rg-tfstate --query "networkRuleSet"`
- Verify role assignments: `az role assignment list --scope /subscriptions/<sub-id>/resourceGroups/rg-tfstate/providers/Microsoft.Storage/storageAccounts/tfstateprod20251215 --query "[].{Principal:principalName,Role:roleDefinitionName}"`

## Troubleshooting
- 403 on state access: ensure your identity has `Storage Blob Data Contributor` and that firewall allows your path (managed identity, private endpoint, or IP whitelist entry)
- Private endpoint issues: confirm provisioning state and DNS resolves to a private IP (`nslookup tfstateprod20251215.blob.core.windows.net` from the VNet)
- SAS token fails: verify expiry and permissions; regenerate if in doubt

## Related Docs
- Backend authentication and rollback: TERRAFORM_STATE_ACCESS.md
- High-level Terraform workflow: README.md
