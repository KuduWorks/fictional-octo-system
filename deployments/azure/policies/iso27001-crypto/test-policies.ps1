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
$storageTestName = "test$(Get-Random -Minimum 10000 -Maximum 99999)" # Storage account names must be globally unique and lowercase
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
$storageTestName2 = "test$(Get-Random -Minimum 10000 -Maximum 99999)" # Storage account names must be globally unique and lowercase
az storage account create `
    --name $storageTestName2 `
    --resource-group $ResourceGroupName `
    --min-tls-version TLS1_0 `
    --sku Standard_LRS 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Policy failed - Storage account created with TLS 1.0!" -ForegroundColor Red
} else {
    Write-Host "✅ Policy working - Storage account TLS 1.0 blocked" -ForegroundColor Green
}

# Test 3: Compliant Storage Account (Should PASS)
Write-Host "`n✅ Testing compliant Storage Account (should pass)..." -ForegroundColor Green
$storageTestName3 = "test$(Get-Random -Minimum 10000 -Maximum 99999)" # Storage account names must be globally unique and lowercase
az storage account create `
    --name $storageTestName3 `
    --resource-group $ResourceGroupName `
    --https-traffic-only true `
    --min-tls-version TLS1_2 `
    --allow-blob-public-access false `
    --sku Standard_LRS

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compliant storage account created successfully" -ForegroundColor Green
    
    # Clean up successful resource
    az storage account delete --name $storageTestName3 --resource-group $ResourceGroupName --yes
} else {
    Write-Host "⚠️  Unexpected failure creating compliant storage account" -ForegroundColor Red
}

# Application Gateway Tests require prerequisite resources
Write-Host "`n🔧 Setting up Application Gateway test prerequisites..." -ForegroundColor Yellow

# Create VNet and Subnet for Application Gateway
$vnetName = "test-vnet"
$subnetName = "appgw-subnet"
az network vnet create `
    --name $vnetName `
    --resource-group $ResourceGroupName `
    --address-prefix "10.0.0.0/16" `
    --subnet-name $subnetName `
    --subnet-prefix "10.0.0.0/24"

# Create Public IP for Application Gateway
$publicIpName = "appgw-pip"
az network public-ip create `
    --name $publicIpName `
    --resource-group $ResourceGroupName `
    --allocation-method Static `
    --sku Standard

# Test 4: Application Gateway with TLS 1.0 (Should FAIL - policy requires TLS 1.2+)
Write-Host "`n❌ Testing Application Gateway with TLS 1.0 (should fail)..." -ForegroundColor Red
$appGwName1 = "testappgw$(Get-Random -Minimum 1000 -Maximum 9999)"
az network application-gateway create `
    --name $appGwName1 `
    --resource-group $ResourceGroupName `
    --vnet-name $vnetName `
    --subnet $subnetName `
    --public-ip-address $publicIpName `
    --sku Standard_v2 `
    --min-capacity 1 `
    --ssl-policy-type Custom `
    --ssl-policy-min-protocol-version TLSv1_0 2>$null

if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠️  Policy failed - Application Gateway created with TLS 1.0!" -ForegroundColor Red
    az network application-gateway delete --name $appGwName1 --resource-group $ResourceGroupName --yes --no-wait
} else {
    Write-Host "✅ Policy working - Application Gateway TLS 1.0 blocked" -ForegroundColor Green
}

# Test 5: Compliant Application Gateway with TLS 1.2+ (Should PASS)
Write-Host "`n✅ Testing compliant Application Gateway with TLS 1.2+ (should pass)..." -ForegroundColor Green
$appGwName2 = "testappgw$(Get-Random -Minimum 1000 -Maximum 9999)"
az network application-gateway create `
    --name $appGwName2 `
    --resource-group $ResourceGroupName `
    --vnet-name $vnetName `
    --subnet $subnetName `
    --public-ip-address $publicIpName `
    --sku Standard_v2 `
    --min-capacity 1 `
    --ssl-policy-type Predefined `
    --ssl-policy-name AppGwSslPolicy20220101S

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Compliant Application Gateway created successfully" -ForegroundColor Green
    az network application-gateway delete --name $appGwName2 --resource-group $ResourceGroupName --yes --no-wait
} else {
    Write-Host "⚠️  Unexpected failure creating compliant Application Gateway" -ForegroundColor Red
}

# Test 6: Check Policy Compliance Status
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