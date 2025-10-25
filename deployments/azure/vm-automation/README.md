# VM with Automated Start/Stop Schedule

Terraform configuration to deploy a secure Azure VM with automated shutdown at **7:00 PM** and startup at **7:00 AM** Finnish time (Europe/Helsinki timezone).

## Overview

This deployment includes:
- ✅ Linux VM (Ubuntu 22.04 LTS) with encryption at host enabled
- ✅ **Private IP only** - No public IP on VM for enhanced security
- ✅ **Azure Bastion** for secure SSH access (no internet exposure)
- ✅ **NAT Gateway** for secure outbound internet connectivity
- ✅ Virtual Network with dedicated subnets (VM, Bastion)
- ✅ Network Security Group with restrictive rules
- ✅ Azure Automation Account with managed identity
- ✅ PowerShell runbooks for VM start/stop operations
- ✅ Automated schedules for daily shutdown (7 PM) and startup (7 AM) Finnish time
- ✅ ISO 27001 compliant (encryption at host, private networking)

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Azure Subscription                           │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │         Resource Group (rg-vm-automation-dev)              │    │
│  │                                                             │    │
│  │  ┌──────────────────────────────────────────────────┐      │    │
│  │  │  Virtual Network (10.0.0.0/16)                   │      │    │
│  │  │                                                   │      │    │
│  │  │  ┌─────────────────┐     ┌──────────────────┐   │      │    │
│  │  │  │  VM Subnet      │     │ Bastion Subnet   │   │      │    │
│  │  │  │  10.0.1.0/24    │     │ 10.0.2.0/26      │   │      │    │
│  │  │  │                 │     │                  │   │      │    │
│  │  │  │  ┌───────────┐  │     │  ┌────────────┐ │   │      │    │
│  │  │  │  │    VM     │  │     │  │   Bastion  │ │   │      │    │
│  │  │  │  │ Private IP│◄─┼─────┼──│    Host    │ │   │      │    │
│  │  │  │  │ (No Pub)  │  │     │  │            │ │   │      │    │
│  │  │  │  └─────┬─────┘  │     │  └──────▲─────┘ │   │      │    │
│  │  │  │        │        │     │         │       │   │      │    │
│  │  │  │        │        │     └─────────┼───────┘   │      │    │
│  │  │  │        │        │               │           │      │    │
│  │  │  │    ┌───▼────┐   │        Public IP         │      │    │
│  │  │  │    │  NAT   │   │         (Bastion)        │      │    │
│  │  │  │    │Gateway │───┼──► Internet Access       │      │    │
│  │  │  │    │        │   │         (You)            │      │    │
│  │  │  │    └────────┘   │                          │      │    │
│  │  │  │    Public IP    │                          │      │    │
│  │  │  │   (Outbound)    │                          │      │    │
│  │  │  └─────────────────┘                          │      │    │
│  │  └──────────────────────────────────────────────────────┘      │
│  │                                                             │    │
│  │  ┌──────────────────────────────────────────────────┐      │    │
│  │  │  Automation Account                              │      │    │
│  │  │  • Shutdown Runbook (19:00 Finnish Time)         │      │    │
│  │  │  • Startup Runbook (07:00 Finnish Time)          │      │    │
│  │  │  • Managed Identity with VM Contributor Role     │      │    │
│  │  └──────────────────────────────────────────────────┘      │    │
│  └────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────┘

Security Features:
✅ No public IP on VM (private network only)
✅ Azure Bastion for secure access (HTTPS/4443)
✅ NAT Gateway for controlled outbound traffic
✅ NSG allows SSH from Bastion subnet only
✅ Encryption at host enabled
✅ Managed identities (no stored credentials)
```

## Prerequisites

1. **Terraform** >= 1.0
2. **Azure CLI** installed and logged in (`az login`)
3. **SSH key pair** generated
4. **Permissions**:
   - Contributor or Owner role on subscription
   - Ability to create managed identities
   - Ability to assign RBAC roles

## Quick Start

### 1. Generate SSH Key (if you don't have one)

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_azure -C "azure-vm"

# View your public key
cat ~/.ssh/id_rsa_azure.pub
```

### 2. Configure Variables

Edit `terraform.tfvars`:

```hcl
# REQUIRED: Set your VM name and SSH key
vm_name        = "dev-vm-01"
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EA... your-key-here"

# OPTIONAL: Restrict SSH access to your IP
allowed_ssh_source_ip = "203.0.113.42"  # Your IP address
```

### 3. Deploy

```bash
# Navigate to folder
cd deployments/azure/vm-automation

# Initialize Terraform
terraform init

# Preview deployment
terraform plan

# Deploy
terraform apply
```

### 4. Connect to Your VM

After deployment, connect via Azure Bastion:

```bash
# View connection instructions
terraform output connection_instructions

# Get private IP
terraform output private_ip_address
```

#### Option 1: Azure Portal (Easiest)

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Virtual Machines** → **dev-vm-01**
3. Click **Connect** → **Bastion**
4. Enter username: `azureuser`
5. Select **SSH Private Key from Local File**
6. Upload your private key file (`~/.ssh/id_rsa_azure`)
7. Click **Connect**

#### Option 2: Azure CLI

```bash
# Connect via Bastion using Azure CLI
az network bastion ssh \
  --name $(terraform output -raw bastion_host_name) \
  --resource-group $(terraform output -raw resource_group_name) \
  --target-resource-id $(terraform output -raw vm_id) \
  --auth-type ssh-key \
  --username azureuser \
  --ssh-key ~/.ssh/id_rsa_azure
```

## Configuration Options

### VM Sizes

| Size | vCPU | RAM | Disk | Use Case | Monthly Cost* |
|------|------|-----|------|----------|---------------|
| Standard_B1s | 1 | 1 GB | 4 GB | Minimal workloads | ~$10 |
| Standard_B2s | 2 | 4 GB | 8 GB | Dev/Test (default) | ~$40 |
| Standard_D2s_v3 | 2 | 8 GB | 16 GB | Production | ~$100 |
| Standard_D4s_v3 | 4 | 16 GB | 32 GB | High-performance | ~$200 |

*Approximate costs for Sweden Central region with auto-shutdown enabled (12h/day usage)

Edit in `terraform.tfvars`:
```hcl
vm_size = "Standard_B2s"
```

### Operating Systems

#### Ubuntu 22.04 LTS (Default)
```hcl
vm_image_publisher = "Canonical"
vm_image_offer     = "0001-com-ubuntu-server-jammy"
vm_image_sku       = "22_04-lts-gen2"
```

#### Ubuntu 20.04 LTS
```hcl
vm_image_publisher = "Canonical"
vm_image_offer     = "0001-com-ubuntu-server-focal"
vm_image_sku       = "20_04-lts-gen2"
```

#### Windows Server 2022
```hcl
vm_image_publisher = "MicrosoftWindowsServer"
vm_image_offer     = "WindowsServer"
vm_image_sku       = "2022-datacenter-azure-edition"
```

**Note**: For Windows VMs, you'll need to modify the resource type from `azurerm_linux_virtual_machine` to `azurerm_windows_virtual_machine` and configure RDP instead of SSH.

### Schedule Times

Edit shutdown and startup times in `terraform.tfvars`:

```hcl
shutdown_time = "19:00"  # 7:00 PM Finnish time
startup_time  = "07:00"  # 7:00 AM Finnish time
```

**Note**: The automation uses `Europe/Helsinki` timezone which automatically handles daylight saving time (EET/EEST).

### Security: Azure Bastion Configuration

Azure Bastion provides secure RDP/SSH connectivity without exposing VMs to the public internet.

**Bastion SKU Options:**

| SKU | Features | Monthly Cost* | Best For |
|-----|----------|---------------|----------|
| **Basic** | Standard SSH/RDP via Portal, native client support | ~$140 | Most use cases |
| **Standard** | All Basic features + IP-based connection, custom ports, file transfer, shareable links | ~$140 + usage | Advanced scenarios |

Edit in `terraform.tfvars`:
```hcl
bastion_sku = "Basic"  # or "Standard"
```

**Note**: Both SKUs have same base cost. Standard includes advanced features that may incur additional usage charges.

## Automation Details

### How It Works

1. **Azure Automation Account** with System-Assigned Managed Identity
2. **RBAC Role Assignment**: Automation account has "Virtual Machine Contributor" role on resource group
3. **PowerShell Runbooks**:
   - `Shutdown-VM`: Stops the VM using `Stop-AzVM`
   - `Startup-VM`: Starts the VM using `Start-AzVM`
4. **Schedules**: Daily recurring jobs linked to runbooks
5. **Timezone-Aware**: Uses `Europe/Helsinki` timezone (handles DST automatically)

### Manual Start/Stop

#### Using Azure CLI

```bash
# Stop VM manually
az vm stop --resource-group rg-vm-automation-dev --name dev-vm-01

# Start VM manually
az vm start --resource-group rg-vm-automation-dev --name dev-vm-01

# Check VM status
az vm get-instance-view \
  --resource-group rg-vm-automation-dev \
  --name dev-vm-01 \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  -o tsv
```

#### Using Azure Portal

1. Go to Azure Portal → Virtual Machines
2. Select your VM (`dev-vm-01`)
3. Click **Stop** or **Start** button at the top

### View Automation Jobs

```bash
# List recent automation jobs
az automation job list \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation \
  --query "[].{Name:runbookName, Status:status, StartTime:startTime}" \
  -o table
```

Or view in Azure Portal:
1. Navigate to Automation Account
2. Click **Jobs** under Process Automation
3. View job history, logs, and status

## Post-Deployment Verification

### 1. Check VM Status

```bash
# View all outputs
terraform output

# Get SSH connection string
terraform output ssh_connection_string

# Get public IP
terraform output public_ip_address
```

### 2. Test SSH Connection

```bash
ssh -i ~/.ssh/id_rsa_azure azureuser@<public-ip>
```

### 3. Verify Automation Schedules

```bash
# List schedules
az automation schedule list \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation \
  --query "[].{Name:name, Frequency:frequency, NextRun:nextRun, Timezone:timeZone}" \
  -o table
```

Expected output:
```
Name                Frequency    NextRun                      Timezone
------------------  -----------  --------------------------  ----------------
Shutdown-Schedule   Day          2025-10-26T17:00:00+00:00   Europe/Helsinki
Startup-Schedule    Day          2025-10-26T05:00:00+00:00   Europe/Helsinki
```

### 4. Test Runbooks Manually

Test the shutdown runbook:

```bash
az automation runbook start \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation \
  --name Shutdown-VM \
  --parameters "resourcegroupname=rg-vm-automation-dev" "vmname=dev-vm-01"
```

Test the startup runbook:

```bash
az automation runbook start \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation \
  --name Startup-VM \
  --parameters "resourcegroupname=rg-vm-automation-dev" "vmname=dev-vm-01"
```

## Cost Optimization

### Estimated Monthly Costs

With auto-shutdown enabled (12h/day, 5 days/week):

| Component | Monthly Cost* | Notes |
|-----------|---------------|-------|
| VM (Standard_B2s, 60h/week) | ~$25 | 2 vCPU, 4GB RAM |
| Storage (Premium SSD 30GB) | ~$5 | OS disk |
| NAT Gateway | ~$35 | ~$33 base + ~$2 data processing (10GB) |
| Azure Bastion (Basic) | ~$140 | Always-on service |
| Public IPs (2x Static) | ~$8 | NAT Gateway + Bastion |
| Networking (Minimal) | ~$2 | VNet, NSG |
| Automation Account | Free | Basic tier |
| **Total** | **~$215/month** | With Bastion security |

**Without Bastion (Public IP + SSH)**: ~$36/month  
**Bastion Premium**: ~$179/month for secure access

*Approximate costs for Sweden Central region. Actual costs may vary.

### Cost Optimization Strategies

1. **For Dev/Test**: Consider using **Standard SKU** Bastion only during business hours
   - Deploy Bastion manually when needed
   - Delete Bastion when not in use (saves ~$140/month)
   - Re-deploy with Terraform when needed

2. **Shared Bastion**: Use one Bastion for multiple VMs in same VNet
   - Deploy Bastion separately
   - Connect multiple VMs to same VNet
   - Share cost across VMs

3. **Alternative Access Methods** (Lower cost, less secure):
   - Just-In-Time (JIT) VM Access via Microsoft Defender (~$15/month per VM)
   - VPN Gateway (~$27/month) for site-to-site access
   - Public IP with NSG restrictions (~$4/month) - least secure

4. **VM Size Optimization**:
   - Standard_B1s: ~$10/month (1 vCPU, 1GB) - minimal workloads
   - Standard_B2s: ~$25/month (2 vCPU, 4GB) - default
   - Standard_D2s_v3: ~$50/month (2 vCPU, 8GB) - production

5. **NAT Gateway Optimization**:
   - Monitor data processing charges
   - Use private endpoints for Azure services to avoid NAT Gateway charges
   - Typical usage: ~10GB/month = ~$2 in data processing fees

## Monitoring

### View VM Metrics

```bash
# CPU usage (last hour)
az monitor metrics list \
  --resource $(terraform output -raw vm_id) \
  --metric "Percentage CPU" \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --interval PT1M \
  --query "value[].timeseries[].data[].[timeStamp,average]" \
  -o table
```

### Set Up Alerts (Optional)

```bash
# Create alert for high CPU usage
az monitor metrics alert create \
  --name "High CPU Alert" \
  --resource-group rg-vm-automation-dev \
  --scopes $(terraform output -raw vm_id) \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m
```

## Troubleshooting

### Issue: Runbook Fails with Authentication Error

**Symptom**: 
```
Error: Connect-AzAccount: No account found in the context
```

**Solution**:
1. Verify managed identity is enabled on automation account
2. Check RBAC role assignment exists:
```bash
az role assignment list \
  --scope /subscriptions/<sub-id>/resourceGroups/rg-vm-automation-dev \
  --query "[?roleDefinitionName=='Virtual Machine Contributor']" \
  -o table
```

### Issue: Schedule Doesn't Trigger

**Symptom**: VM doesn't start/stop at scheduled time

**Solutions**:
1. Check schedule is enabled:
```bash
az automation schedule show \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation \
  --name Shutdown-Schedule
```

2. Verify job schedule link exists:
```bash
az automation job-schedule list \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation
```

3. Check runbook published:
```bash
az automation runbook show \
  --resource-group rg-vm-automation-dev \
  --automation-account-name dev-vm-01-automation \
  --name Shutdown-VM \
  --query "state"
```

### Issue: Cannot SSH to VM

**Solutions**:

1. **Check VM is running**:
```bash
az vm get-instance-view \
  --resource-group rg-vm-automation-dev \
  --name dev-vm-01 \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  -o tsv
```

2. **Verify Bastion is deployed**:
```bash
az network bastion show \
  --resource-group rg-vm-automation-dev \
  --name dev-vm-01-bastion \
  --query "provisioningState"
```

3. **Check NSG allows traffic from Bastion**:
```bash
az network nsg show \
  --resource-group rg-vm-automation-dev \
  --name dev-vm-01-vm-nsg \
  --query "securityRules[?name=='Allow-SSH-From-Bastion']"
```

4. **Use Azure Portal if CLI fails**:
   - Navigate to VM → Connect → Bastion
   - Ensure you're using the correct SSH key

### Issue: Cannot Connect via Bastion

**Symptom**: Bastion connection fails or times out

**Solutions**:

1. **Check Bastion subnet exists**:
```bash
az network vnet subnet show \
  --resource-group rg-vm-automation-dev \
  --vnet-name dev-vm-01-vnet \
  --name AzureBastionSubnet
```

2. **Verify Bastion public IP**:
```bash
az network public-ip show \
  --resource-group rg-vm-automation-dev \
  --name dev-vm-01-bastion-ip \
  --query "ipAddress"
```

3. **Check VM has private IP in correct subnet**:
```bash
terraform output private_ip_address
```

### Issue: VM Cannot Access Internet

**Symptom**: Cannot download packages, updates, etc.

**Solutions**:

1. **Verify NAT Gateway is attached to VM subnet**:
```bash
az network vnet subnet show \
  --resource-group rg-vm-automation-dev \
  --vnet-name dev-vm-01-vnet \
  --name vm-subnet \
  --query "natGateway"
```

2. **Check NAT Gateway public IP**:
```bash
terraform output nat_gateway_ip
```

3. **Test outbound connectivity from VM**:
```bash
# After connecting via Bastion
curl ifconfig.me
# Should return NAT Gateway IP
```

### Issue: "Encryption at host not supported" Error

**Symptom**:
```
Error: The selected VM size does not support encryption at host
```

**Solution**: Change to a supported VM size or disable encryption:

```hcl
# In main.tf, set to false or change VM size
encryption_at_host_enabled = false
```

Supported sizes include: B-series, D-series, E-series (most modern sizes)

## Updating the Configuration

### Change Shutdown/Startup Times

1. Edit `terraform.tfvars`:
```hcl
shutdown_time = "20:00"  # Change to 8 PM
startup_time  = "06:00"  # Change to 6 AM
```

2. Re-apply:
```bash
terraform apply
```

**Note**: Current implementation uses hardcoded times in schedule resources. For dynamic time changes, you'll need to destroy and recreate schedules.

### Add Additional VMs

Duplicate the VM resources with different names or use `count` parameter:

```hcl
# In main.tf
resource "azurerm_linux_virtual_machine" "vm" {
  count = var.vm_count
  name  = "${var.vm_name}-${count.index + 1}"
  # ... rest of config
}
```

## Cleanup

### Remove All Resources

```bash
terraform destroy
```

### Remove Specific Components

```bash
# Remove only automation (keep VM running 24/7)
terraform destroy -target=azurerm_automation_account.automation

# Remove only VM (keep automation account)
terraform destroy -target=azurerm_linux_virtual_machine.vm
```

## Security Considerations

1. ✅ **Encryption at host enabled** for ISO 27001 compliance
2. ✅ **Managed Identity** for automation (no stored credentials)
3. ✅ **RBAC with least privilege** (VM Contributor scope limited to resource group)
4. ⚠️ **SSH access** - Restrict `allowed_ssh_source_ip` to your IP
5. ⚠️ **No Azure Bastion** - Consider adding for production environments
6. ⚠️ **No backup configured** - Add Azure Backup for production VMs

### Production Hardening Checklist

- [ ] Change `allowed_ssh_source_ip` from `*` to specific IP/range
- [ ] Enable Azure Backup for VM
- [ ] Configure Azure Monitor alerts
- [ ] Implement Azure Bastion instead of public IP
- [ ] Enable Azure Disk Encryption (ADE) if required
- [ ] Configure Network Watcher for traffic analysis
- [ ] Set up Log Analytics workspace for centralized logging
- [ ] Enable Microsoft Defender for Cloud

## Additional Resources

- [Azure Automation Documentation](https://docs.microsoft.com/en-us/azure/automation/)
- [Azure VM Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/)
- [Azure Virtual Machines Documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/)
- [Terraform AzureRM Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Support

For issues:
1. Check the troubleshooting section above
2. Review automation job logs in Azure Portal
3. Check Terraform state: `terraform show`
4. Review Azure Activity Log for deployment errors

---

**Created**: October 25, 2025  
**Terraform Version**: >= 1.0  
**AzureRM Provider**: ~> 3.0  
**Default Region**: Sweden Central  
**Automation**: 7 AM start, 7 PM shutdown (Finnish time)
