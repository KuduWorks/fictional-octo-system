# Quick Setup Guide

## Step-by-Step Deployment

### 1. Generate SSH Key

```bash
# Generate new SSH key pair
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_azure -C "azure-vm-automation"

# View your public key (copy this)
cat ~/.ssh/id_ed25519_azure.pub
```

### 2. Edit Configuration

Open `terraform.tfvars` and update:

```hcl
# REQUIRED: Update these values
vm_name        = "your-vm-name"
ssh_public_key = "paste-your-public-key-here"

# OPTIONAL: Choose Bastion SKU
bastion_sku = "Basic"  # or "Standard" for advanced features
```

### 3. Deploy

```bash
# Login to Azure
az login

# Set subscription (if you have multiple)
az account set --subscription "your-subscription-id"

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (type 'yes' when prompted)
# Note: This will take 10-15 minutes due to Bastion deployment
terraform apply
```

### 4. Connect via Azure Bastion

#### Option 1: Azure Portal (Recommended)

```bash
# View connection instructions
terraform output connection_instructions
```

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Virtual Machines** → **your-vm-name**
3. Click **Connect** → **Bastion**
4. Enter username: `azureuser`
5. Select **SSH Private Key from Local File**
6. Upload your private key (`~/.ssh/id_rsa_azure`)
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

## Verify Automation

```bash
# Check schedules are created
terraform output startup_schedule
terraform output shutdown_schedule

# View in Azure Portal
# Navigate to: Automation Accounts → <vm-name>-automation → Schedules
```

## Quick Commands

```bash
# Show all outputs
terraform output

# View connection instructions
terraform output connection_instructions

# Get VM private IP
terraform output private_ip_address

# Get NAT Gateway public IP (for outbound traffic)
terraform output nat_gateway_ip

# Check VM status
az vm get-instance-view \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw vm_name) \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  -o tsv

# Manually stop VM
az vm stop \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw vm_name)

# Manually start VM
az vm start \
  --resource-group $(terraform output -raw resource_group_name) \
  --name $(terraform output -raw vm_name)
```

## Cleanup

```bash
# Remove all resources
terraform destroy
```

## Estimated Cost

With auto-shutdown (12h/day, 5 days/week):

| Component | Monthly Cost |
|-----------|--------------|
| VM (Standard_B2s) | ~$25 |
| Storage | ~$5 |
| **Azure Bastion** | **~$140** |
| NAT Gateway | ~$35 |
| Public IPs (2x) | ~$8 |
| Networking | ~$2 |
| **Total** | **~$215/month** |

**Security Investment**: Azure Bastion adds ~$140/month but provides enterprise-grade security:
- ✅ No public IP on VM
- ✅ Zero-trust network access
- ✅ No VPN needed
- ✅ Audit logging built-in
- ✅ MFA integration

**Cost Savings**: For dev/test, deploy Bastion only when needed or use one Bastion for multiple VMs.

Full cost breakdown in [README.md](README.md)
