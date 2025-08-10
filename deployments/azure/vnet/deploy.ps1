param(
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "East US",
    
    [Parameter(Mandatory=$false)]
    [string]$TemplateFile = "main.bicep",
    
    [Parameter(Mandatory=$false)]
    [string]$ParametersFile = "main.parameters.json"
)

# Check if Azure PowerShell is installed and connected
try {
    $context = Get-AzContext
    if (-not $context) {
        Write-Host "Please connect to Azure first using Connect-AzAccount" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Azure PowerShell module not found. Please install it first:" -ForegroundColor Red
    Write-Host "Install-Module -Name Az -Repository PSGallery -Force" -ForegroundColor Yellow
    exit 1
}

Write-Host "Starting VNet deployment..." -ForegroundColor Green
Write-Host "Resource Group: $ResourceGroupName" -ForegroundColor Cyan
Write-Host "Location: $Location" -ForegroundColor Cyan

# Check if resource group exists, create if it doesn't
$rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if (-not $rg) {
    Write-Host "Resource group '$ResourceGroupName' not found. Creating..." -ForegroundColor Yellow
    try {
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location
        Write-Host "Resource group created successfully." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create resource group: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Deploy the template
try {
    Write-Host "Deploying Bicep template..." -ForegroundColor Yellow
    
    $deployment = New-AzResourceGroupDeployment `
        -ResourceGroupName $ResourceGroupName `
        -TemplateFile $TemplateFile `
        -TemplateParameterFile $ParametersFile `
        -Verbose
    
    if ($deployment.ProvisioningState -eq "Succeeded") {
        Write-Host "`nDeployment completed successfully!" -ForegroundColor Green
        Write-Host "`n--- Deployment Outputs ---" -ForegroundColor Cyan
        
        foreach ($output in $deployment.Outputs.GetEnumerator()) {
            Write-Host "$($output.Key): $($output.Value.Value)" -ForegroundColor White
        }
        
        Write-Host "`n--- Next Steps ---" -ForegroundColor Cyan
        Write-Host "1. Review the deployed resources in the Azure portal" -ForegroundColor White
        Write-Host "2. Update Network Security Group rules as needed" -ForegroundColor White
        Write-Host "3. Add additional subnets if required" -ForegroundColor White
    }
    else {
        Write-Host "Deployment failed with state: $($deployment.ProvisioningState)" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "Deployment failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
