# ARM Template Deployment Script for Azure Region Control Policies
# This script deploys Azure policies using ARM templates to restrict resource deployment to Sweden Central

param(
    [string]$SubscriptionId = "",
    [string]$Location = "swedencentral",
    [switch]$WhatIf = $false,
    [switch]$Force = $false
)

# Variables
$DeploymentName = "azure-policy-arm-sweden-central-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
$TemplateFile = "arm-template.json"
$ParametersFile = "arm-template.parameters.json"

Write-Host "=== ARM Template Deployment for Azure Region Control Policies ===" -ForegroundColor Blue

# Check if Azure CLI is installed
try {
    $azVersion = az version --output json | ConvertFrom-Json
    Write-Host "Azure CLI version: $($azVersion.'azure-cli')" -ForegroundColor Green
} catch {
    Write-Host "Error: Azure CLI is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if user is logged in
try {
    $currentAccount = az account show --output json | ConvertFrom-Json
    Write-Host "Current account: $($currentAccount.user.name)" -ForegroundColor Green
} catch {
    Write-Host "You are not logged in to Azure. Please log in..." -ForegroundColor Yellow
    az login
    $currentAccount = az account show --output json | ConvertFrom-Json
}

# Get current subscription if not provided
if ([string]::IsNullOrEmpty($SubscriptionId)) {
    $SubscriptionId = $currentAccount.id
    Write-Host "Using current subscription: $SubscriptionId" -ForegroundColor Blue
}

# Set the subscription
az account set --subscription $SubscriptionId

Write-Host "Current subscription:" -ForegroundColor Blue
az account show --query "{subscriptionId:id, subscriptionName:name, tenantId:tenantId}" --output table

# Validate the ARM template
Write-Host "Validating ARM template..." -ForegroundColor Yellow
$validationResult = az deployment sub validate `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParametersFile `
    --only-show-errors 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "ARM template validation successful!" -ForegroundColor Green
} else {
    Write-Host "ARM template validation failed:" -ForegroundColor Red
    Write-Host $validationResult -ForegroundColor Red
    exit 1
}

# Preview the deployment (what-if)
Write-Host "Running deployment preview (what-if analysis)..." -ForegroundColor Yellow
az deployment sub what-if `
    --location $Location `
    --template-file $TemplateFile `
    --parameters $ParametersFile `
    --name $DeploymentName

if ($WhatIf) {
    Write-Host "What-if analysis completed. Exiting due to -WhatIf flag." -ForegroundColor Yellow
    exit 0
}

# Ask for confirmation unless -Force is specified
if (-not $Force) {
    $response = Read-Host "Do you want to proceed with the ARM template deployment? (y/N)"
    if ($response -notmatch "^[Yy]$") {
        Write-Host "Deployment cancelled." -ForegroundColor Yellow
        exit 0
    }
}

# Deploy the policies using ARM template
Write-Host "Deploying Azure policies using ARM template..." -ForegroundColor Blue
try {
    $deploymentResult = az deployment sub create `
        --location $Location `
        --template-file $TemplateFile `
        --parameters $ParametersFile `
        --name $DeploymentName `
        --query "properties.provisioningState" `
        --output tsv

    if ($deploymentResult -eq "Succeeded") {
        Write-Host "=== ARM Template Deployment Successful! ===" -ForegroundColor Green
        
        # Get deployment outputs
        Write-Host "Deployment outputs:" -ForegroundColor Blue
        az deployment sub show `
            --name $DeploymentName `
            --query "properties.outputs" `
            --output table
        
        # List the created policy assignments
        Write-Host "Policy assignments created:" -ForegroundColor Blue
        az policy assignment list `
            --query "[?contains(name, 'allowed-regions') || contains(name, 'rg-location') || contains(name, 'region-control')].{Name:name, DisplayName:displayName, Scope:scope, EnforcementMode:enforcementMode}" `
            --output table
        
        Write-Host "Region control policies have been successfully deployed using ARM template!" -ForegroundColor Green
        Write-Host "All future resource deployments will be restricted to Sweden Central." -ForegroundColor Green
        
        # Show Azure Portal link
        Write-Host "View your deployment in Azure Portal:" -ForegroundColor Blue
        $portalUrl = "https://portal.azure.com/#blade/HubsExtension/DeploymentDetailsBlade/overview/id/%2Fsubscriptions%2F$SubscriptionId%2Fproviders%2FMicrosoft.Resources%2Fdeployments%2F$DeploymentName"
        Write-Host $portalUrl -ForegroundColor Blue
        
    } else {
        Write-Host "Deployment failed with status: $deploymentResult" -ForegroundColor Red
        Write-Host "Please check the deployment details in Azure portal." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error during deployment:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

Write-Host "=== ARM Template Deployment Complete ===" -ForegroundColor Blue