# Naming Convention Module Tests

This directory contains test configurations to validate the naming convention module.

## Running Tests

```bash
cd deployments/azure/modules/naming-convention/test
terraform init
terraform validate
terraform plan
```

## Test Coverage

The test configuration validates:

### Multiple Environments
- **Dev** (East US) - `testapp` workload
- **Prod** (West Europe) - `api` workload
- **Stage** (North Europe) - `finops` workload

### All Resource Types
- Storage Accounts (with sanitization)
- Virtual Machines
- Virtual Networks
- Subnets (with purpose)
- Network Interfaces
- Public IPs
- Network Security Groups
- Resource Groups
- Key Vaults (with length limits)
- App Services
- Function Apps
- Container Instances
- AKS Clusters
- Cosmos DB
- SQL Servers and Databases
- Log Analytics Workspaces
- Application Insights

### Naming Rules
- ✅ Storage account sanitization (lowercase, no hyphens, 3-24 chars)
- ✅ Key Vault length limits (max 24 chars)
- ✅ 3-character region codes
- ✅ Instance numbering (01-99)
- ✅ Environment validation (dev/test/stage/prod)
- ✅ Workload validation (2-10 chars)

### Tag Generation
- ✅ Standard tags (Environment, Region, Workload, ManagedBy, CreatedDate)
- ✅ Additional custom tags merge correctly

## Expected Results

### Dev Environment (East US)
```
Storage Account:   sttestappdeveus01
Virtual Machine:   vm-testapp-dev-eus-01
Virtual Network:   vnet-testapp-dev-eus
Subnet:            snet-testapp-web
Resource Group:    rg-testapp-dev-eus
Key Vault:         kv-testapp-dev-eus-01
Region Code:       eus
```

### Prod Environment (West Europe)
```
Storage Account:   stapiprodweu99
Virtual Machine:   vm-api-prod-weu-99
Virtual Network:   vnet-api-prod-weu
Subnet:            snet-api-data
Resource Group:    rg-api-prod-weu
Key Vault:         kv-api-prod-weu-99
Region Code:       weu
```

### Stage Environment (North Europe)
```
Storage Account:   stfinopsstageneu05
Virtual Machine:   vm-finops-stage-neu-05
Virtual Network:   vnet-finops-stage-neu
Resource Group:    rg-finops-stage-neu
Key Vault:         kv-finops-stage-neu-05
Region Code:       neu
```

## Validation Checks

The test outputs include length validations to ensure Azure naming compliance:
- Storage accounts: 3-24 characters ✅
- Key Vaults: 3-24 characters ✅
- Virtual Machines: 1-64 characters ✅

All tests passed successfully!
