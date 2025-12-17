# Script to clean up old IP addresses from storage account firewall (legacy - disabled)
#Requires -Version 7.0
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

throw "Legacy script is disabled. Use Terraform with storage_access_method and AAD/OIDC instead."

$STORAGE_ACCOUNT = "<placeholder_storage_account>"
$RESOURCE_GROUP = "<placeholder_resource_group>"

Write-Host "🔍 Getting current IP address..." -ForegroundColor Cyan
try {
    $CURRENT_IP = (Invoke-WebRequest -Uri "https://ifconfig.me/ip" -UseBasicParsing).Content.Trim()
} catch {
    Write-Host "❌ Failed to retrieve current IP address." -ForegroundColor Red
    exit 1
}

if (-not $CURRENT_IP -or -not ($CURRENT_IP -match '^(?:\d{1,3}\.){3}\d{1,3}$')) {
    Write-Host "❌ Invalid IP address retrieved: '$CURRENT_IP'" -ForegroundColor Red
    exit 1
}

Write-Host "📍 Current IP: $CURRENT_IP" -ForegroundColor Green
Write-Host ""

Write-Host "📋 All whitelisted IPs:" -ForegroundColor Cyan
$ALL_IPS = az storage account show `
  --name $STORAGE_ACCOUNT `
  --resource-group $RESOURCE_GROUP `
  --query "networkRuleSet.ipRules[].value" `
  --output tsv `
  --only-show-errors

if ([string]::IsNullOrWhiteSpace($ALL_IPS)) {
    Write-Host "   (none)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✅ No IPs to clean up!" -ForegroundColor Green
    exit 0
}

$IpArray = $ALL_IPS -split "`n" | Where-Object { $_ -ne "" }

foreach ($IP in $IpArray) {
    $IP = $IP.Trim()
    if ($IP -eq $CURRENT_IP) {
        Write-Host "   $IP (current - will keep)" -ForegroundColor Green
    } else {
        Write-Host "   $IP (old - will remove)" -ForegroundColor Yellow
    }
}

Write-Host ""
$response = Read-Host "❓ Remove all IPs except current ($CURRENT_IP)? (y/N)"

if ($response -match "^[Yy]$") {
    Write-Host ""
    Write-Host "🧹 Cleaning up old IPs..." -ForegroundColor Cyan
    
    # First, ensure current IP is added
    try {
        az storage account network-rule add `
            --account-name $STORAGE_ACCOUNT `
            --resource-group $RESOURCE_GROUP `
            --ip-address $CURRENT_IP `
            --only-show-errors `
            2>$null
    } catch {
        # IP might already exist, ignore error
    }
    
    # Remove all IPs except current
    foreach ($IP in $IpArray) {
        $IP = $IP.Trim()
        if ($IP -ne $CURRENT_IP) {
            Write-Host "   Removing $IP..." -ForegroundColor Yellow
            az storage account network-rule remove `
                --account-name $STORAGE_ACCOUNT `
                --resource-group $RESOURCE_GROUP `
                --ip-address $IP `
                --only-show-errors
        }
    }
    
    Write-Host ""
    Write-Host "✅ Cleanup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📋 Remaining IPs:" -ForegroundColor Cyan
    az storage account show `
        --name $STORAGE_ACCOUNT `
        --resource-group $RESOURCE_GROUP `
        --query "networkRuleSet.ipRules[].value" `
        --output table `
        --only-show-errors
} else {
    Write-Host ""
    Write-Host "❌ Cleanup cancelled." -ForegroundColor Red
}
