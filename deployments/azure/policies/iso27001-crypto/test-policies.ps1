# ISO 27001 Crypto Policies Test Script
param(
    [string]$ResourceGroupName = "policy-test-rg",
    [string]$Location = "swedencentral"
)

Write-Host "🧪 Testing ISO 27001 Cryptography Policies..." -ForegroundColor Green

# Create test resource group
Write-Host "Creating test resource group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location

# Test 1: Storage Account HTTPS Policy (Should FAIL)
Write-Host "`n❌ Testing Storage Account without HTTPS (should fail)..." -ForegroundColor Red
$storageTestName = "test$(Get-Random -Minimum 10000 -Maximum 99999)" # Storage account names must be globally unique but also not exceed 24 characters
az storage account create `
    --name $storageTestName `
    --resource-group $ResourceGroupName `
    --https-traffic-only false `
    --sku Standard_LRS 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Policy failed - Storage account created without HTTPS!" -ForegroundColor Red
} else {
    Write-Host "✅ Policy working - Storage account creation blocked" -ForegroundColor Green
}

# Test 2: Storage Account TLS 1.0 Policy (Should FAIL)
Write-Host "`n❌ Testing Storage Account with TLS 1.0 (should fail)..." -ForegroundColor Red
$storageTestName2 = "test$(Get-Random -Minimum 10000 -Maximum 99999)" # Storage account names must be globally unique but also not exceed 24 characters
az storage account create `
    --name $storageTestName2 `
    --resource-group $ResourceGroupName `
    --min-tls-version TLS1_0 `
    --sku Standard_LRS 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Policy failed - Storage account created with TLS 1.0!" -ForegroundColor Red
} else {
    Write-Host "✅ Policy working - Storage account TLS 1.0 blocked" -ForegroundColor Green

# Test 3: Compliant Storage Account (Should PASS)
Write-Host "`n✅ Testing compliant Storage Account (should pass)..." -ForegroundColor Green
$storageTestName3 = "test$(Get-Random -Minimum 10000 -Maximum 99999)" # Storage account names must be globally unique but also not exceed 24 characters
try {
    az storage account create `
        --name $storageTestName3 `
        --resource-group $ResourceGroupName `
        --https-traffic-only true `
        --min-tls-version TLS1_2 `
        --allow-blob-public-access false `
        --sku Standard_LRS
    Write-Host "✅ Compliant storage account created successfully" -ForegroundColor Green
    
    # Clean up successful resource
    az storage account delete --name $storageTestName3 --resource-group $ResourceGroupName --yes
} catch {
    Write-Host "⚠️  Unexpected failure creating compliant storage account" -ForegroundColor Red
}

# Test 4: Check Policy Compliance Status
Write-Host "`n📊 Checking overall policy compliance..." -ForegroundColor Blue
az policy state list `
    --filter "contains(policyDefinitionName, 'iso27001')" `
    --query "[].{Policy:policyDefinitionName, Resource:resourceId, Compliance:complianceState}" `
    --output table

# Clean up test resource group
Write-Host "`n🧹 Cleaning up test resources..." -ForegroundColor Yellow
az group delete --name $ResourceGroupName --yes --no-wait

Write-Host "`n🎯 Policy testing complete!" -ForegroundColor Green
Write-Host "Check Azure Portal → Policy → Compliance for detailed results" -ForegroundColor Cyan