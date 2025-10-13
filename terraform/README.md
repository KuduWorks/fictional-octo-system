# Terraform Infrastructure for Fictional Octo System
// filepath: c:\Repos\fictional-octo-system\terraform\README.md

This folder contains Terraform code for deploying and managing Azure resources for the Fictional Octo System project.

## Structure

- `backend.tf` — Configures remote state storage in Azure using a Storage Account and Blob Container.
- `variables.tf` — Defines input variables for resource configuration.
- Other `.tf` files — Add your resource definitions here.

## Getting Started

1. **Install Terraform**  
   Download from [terraform.io/downloads](https://www.terraform.io/downloads.html) and add it to your system PATH.

2. **Authenticate to Azure**  
   ```
   az login
   ```

3. **Configure Backend**  
   Update `backend.tf` with your Azure Storage Account, Resource Group, and Container details.

4. **Initialize Terraform**  
   ```
   terraform init
   ```

5. **Plan and Apply**  
   ```
   terraform plan
   terraform apply
   ```

## Variables

See `variables.tf` for configurable options such as:
- `location` — Azure region for deployment
- `resource_group_name` — Resource group name
- `tags` — Resource tags

## Best Practices

- Store state remotely using Azure Storage for collaboration and reliability.
- Do not include credentials in `.tf` files; use Azure CLI authentication or environment variables.
- Use tags for resource management and cost tracking.

## Resources

- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)

---

# Create resource group
az group create --name rg-tfstate --location swedencentral

# Create storage account (with secure settings)
az storage account create --name tfstate20251013 --resource-group rg-tfstate --location swedencentral --sku Standard_LRS --encryption-services blob

# Create blob container

az storage container create --name tfstate --account-name tfstate20251013 --resource-group rg-tfstate