# Legacy Notice: Dynamic IP Terraform Wrappers (Disabled)

The old dynamic IP wrapper scripts are **archived and disabled**. They now live in `terraform/archive/dynamic-ip-legacy/` and exit immediately to avoid accidental use. Do not re-enable them in this public repo.

## Current Approach
- Use Terraform with Azure AD/OIDC and `storage_access_method`.
- Prefer `managed_identity` or `private_endpoint`; use temporary `ip_whitelist` only if you must.

Example `terraform.tfvars`:
```hcl
storage_access_method      = "managed_identity" # or "private_endpoint"; temporary "ip_whitelist" if needed
allowed_ip_addresses       = ["203.0.113.10"]   # only for ip_whitelist
state_storage_account_name = "<state-storage-account-placeholder>"
state_resource_group_name  = "<state-rg-placeholder>"
```
```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

If you think you need the legacy scripts, coordinate with maintainers first.
