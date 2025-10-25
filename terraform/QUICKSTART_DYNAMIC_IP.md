# 🚀 Quick Start - Terraform with Dynamic IP

## Problem Solved ✅

Your IP address changes frequently, but Terraform needs to access the state file in Azure Storage. The storage account has firewall rules that block unknown IPs.

## Solution - Automatic IP Management

Use the provided wrapper scripts that automatically update your IP before running Terraform commands.

---

## Usage

### **Bash (Git Bash on Windows / Linux / macOS)**

```bash
cd /c/Repos/fictional-octo-system/terraform

# Use these instead of 'terraform' commands:
./tf.sh init       # Initialize Terraform
./tf.sh plan       # Plan changes
./tf.sh apply      # Apply changes
./tf.sh destroy    # Destroy resources
```

### **PowerShell (Windows)**

```powershell
cd C:\Repos\fictional-octo-system\terraform

# Use these instead of 'terraform' commands:
.\tf.ps1 init      # Initialize Terraform
.\tf.ps1 plan      # Plan changes
.\tf.ps1 apply     # Apply changes
.\tf.ps1 destroy   # Destroy resources
```

---

## What Happens Behind the Scenes

1. Script detects your current public IP (via ifconfig.me)
2. Adds your IP to the storage account firewall
3. Runs your Terraform command
4. Done! ✨

---

## Maintenance

### Clean up old IPs periodically:

**Bash:**
```bash
./cleanup-old-ips.sh
```

**PowerShell:**
```powershell
.\cleanup-old-ips.ps1
```

This removes all old IPs except your current one, keeping the firewall rules clean.

---

## Manual IP Update (if needed)

If you just need to update your IP without running Terraform:

**Bash:**
```bash
./update-ip.sh
```

**PowerShell:**
```powershell
.\update-ip.ps1
```

---

## Troubleshooting

### "Permission denied" error (Bash on Windows)

```bash
chmod +x *.sh
```

### "Failed to get existing workspaces: StatusCode=403"

Your IP is not whitelisted. Run:
```bash
./update-ip.sh
```

Then try your Terraform command again.

### "Not logged in to Azure"

```bash
az login
```

---

## Files Created

| File | Purpose |
|------|---------|
| `tf.sh` / `tf.ps1` | Terraform wrapper that updates IP automatically |
| `update-ip.sh` / `update-ip.ps1` | Updates your IP in storage firewall |
| `cleanup-old-ips.sh` / `cleanup-old-ips.ps1` | Removes old IP addresses |

---

## Current Setup

- **Storage Account**: `tfstate20251013`
- **Resource Group**: `rg-tfstate`
- **Container**: `tfstate`
- **Current IP**: 176.93.249.12 ✅ (already whitelisted!)

---

## Next Steps

1. **Test the wrapper**:
   ```bash
   ./tf.sh plan
   ```

2. **Set up alias** (optional, for convenience):
   ```bash
   # Add to ~/.bashrc:
   alias tf='cd /c/Repos/fictional-octo-system/terraform && ./tf.sh'
   
   # Then use anywhere:
   tf plan
   tf apply
   ```

3. **Use for your VM deployment**:
   ```bash
   cd /c/Repos/fictional-octo-system/deployments/azure/vm-automation
   cp /c/Repos/fictional-octo-system/terraform/tf.sh .
   cp /c/Repos/fictional-octo-system/terraform/update-ip.sh .
   chmod +x *.sh
   
   ./tf.sh plan
   ./tf.sh apply
   ```

---

## Documentation

- **Full guide**: [TERRAFORM_STATE_ACCESS.md](./TERRAFORM_STATE_ACCESS.md)
- **Storage access options**: [STORAGE_ACCESS.md](./STORAGE_ACCESS.md)
- **VM deployment**: [../deployments/azure/vm-automation/README.md](../deployments/azure/vm-automation/README.md)

---

**That's it!** No more "StatusCode=403" errors. Just use `./tf.sh` instead of `terraform` and you're good to go! 🎉
