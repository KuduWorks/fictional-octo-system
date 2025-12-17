# Archived: Dynamic IP Terraform Wrappers

These wrapper scripts are retained only for emergencies. Prefer native Terraform with `storage_access_method = "ip_whitelist"` (or `managed_identity` / `private_endpoint`) in `terraform.tfvars`.

## Current State
- Storage account: tfstateprod20251215
- Resource group: rg-tfstate
- Container: tfstate-prod
- Scripts location: terraform/archive/dynamic-ip/

## Recommended Path (no wrappers)
```hcl
# terraform.tfvars
storage_access_method      = "ip_whitelist"   # temporary
allowed_ip_addresses       = ["203.0.113.10"]
state_storage_account_name = "tfstateprod20251215"
state_resource_group_name  = "rg-tfstate"
```
```bash
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## If You Must Use the Wrappers
```bash
cd terraform/archive/dynamic-ip
./tf.sh plan   # or apply/destroy
```
The wrapper will add your current public IP to the storage firewall, run Terraform, and exit. Remove old IPs with `./cleanup-old-ips.sh` if needed.

## Quick Commands (manual IP add)
```bash
az storage account network-rule add \
  --account-name tfstateprod20251215 \
  --resource-group rg-tfstate \
  --ip-address $(curl -s ifconfig.me)
```

## Related Docs
- Backend auth and rollback: TERRAFORM_STATE_ACCESS.md
- Access options: STORAGE_ACCESS.md
