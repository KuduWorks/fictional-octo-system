# PowerShell script to update storage account firewall with current IP before Terraform operations

$ErrorActionPreference = "Stop"

$STORAGE_ACCOUNT = "tfstate20251013"
$RESOURCE_GROUP = "rg-tfstate"

Write-Host "🔍 Getting current IP address..." -ForegroundColor Cyan
try {
    $CURRENT_IP = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing).Content.Trim()
    if (-not $CURRENT_IP -or ($CURRENT_IP -notmatch '^\d{1,3}(\.\d{1,3}){3}$')) {
        throw "Failed to retrieve a valid IP address."
    }
    Write-Host "📍 Current IP: $CURRENT_IP" -ForegroundColor Green
} catch {
    Write-Host "❌ Error retrieving current IP address: $_" -ForegroundColor Red
    exit 1
}

Write-Host "🔐 Checking Azure authentication..." -ForegroundColor Cyan
try {
    az account show | Out-Null
} catch {
    Write-Host "❌ Not logged in to Azure. Running 'az login'..." -ForegroundColor Yellow
    az login
}

Write-Host "➕ Adding current IP to storage account firewall..." -ForegroundColor Cyan
try {
    az storage account network-rule add `
        --account-name $STORAGE_ACCOUNT `
        --resource-group $RESOURCE_GROUP `
        --ip-address $CURRENT_IP `
        2>$null
} catch {
    Write-Host "⚠️  IP already exists or addition failed" -ForegroundColor Yellow
}

Write-Host "📋 Current firewall rules:" -ForegroundColor Cyan
az storage account show `
    --name $STORAGE_ACCOUNT `
    --resource-group $RESOURCE_GROUP `
    --query "networkRuleSet.ipRules[].value" `
    --output table

Write-Host ""
Write-Host "✅ IP firewall updated! You can now run Terraform commands." -ForegroundColor Green
Write-Host ""
Write-Host "💡 Tip: Old IPs accumulate. Clean them up periodically:" -ForegroundColor Yellow
Write-Host "   az storage account network-rule remove --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --ip-address <old-ip>" -ForegroundColor Yellow
