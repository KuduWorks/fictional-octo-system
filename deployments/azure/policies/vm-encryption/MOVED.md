# VM Encryption Policy - MOVED

⚠️ **This policy has been moved to the ISO 27001 crypto folder.**

## New Location

```
deployments/azure/policies/iso27001-crypto/
```

## Why?

To consolidate all encryption-related policies (VMs, Storage, SQL, Key Vault, Disks, Kusto, AKS) into a single ISO 27001 A.10.1.1 (Cryptographic Controls) compliance folder.

## What Changed?

- The VM encryption audit policy is now part of the comprehensive ISO 27001 crypto policy set
- Policy name and functionality remain the same: `custom-vm-encryption-audit`
- Policy still audits VMs to ensure they have either EncryptionAtHost OR Azure Disk Encryption
- Metadata updated to include ISO 27001 category and control reference

## Next Steps

1. **If you've already deployed this policy**, destroy it first:
   ```bash
   cd deployments/azure/policies/vm-encryption
   terraform destroy
   ```

2. **Deploy the consolidated ISO 27001 policy set**:
   ```bash
   cd ../iso27001-crypto
   terraform init
   terraform plan
   terraform apply
   ```

## Keep This Folder?

You can safely delete this folder after migrating to the ISO 27001 folder. The policy definition and assignment are identical, just better organized.

---

**Migration Date**: October 19, 2025
**New Policy Count**: 12 policies (was 1)
**ISO 27001 Control**: A.10.1.1 - Cryptographic Controls
