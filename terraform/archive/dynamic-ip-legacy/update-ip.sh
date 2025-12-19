#!/bin/bash
# Legacy script (disabled): updates storage firewall with current IP before Terraform.

set -euo pipefail

echo "This legacy script is disabled. Use Terraform with storage_access_method and AAD/OIDC instead." >&2
exit 1

STORAGE_ACCOUNT="<placeholder_storage_account>"
RESOURCE_GROUP="<placeholder_resource_group>"

echo "🔍 Getting current IP address..."
CURRENT_IP=$(curl -s ifconfig.me)
if [[ -z "$CURRENT_IP" ]]; then
    echo "❌ Failed to retrieve current IP address. Please check your network connection and try again."
    exit 1
fi
echo "📍 Current IP: $CURRENT_IP"

echo "🔐 Checking Azure authentication..."
az account show --only-show-errors > /dev/null 2>&1 || {
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login
}

echo "➕ Adding current IP to storage account firewall..."
az storage account network-rule add \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --ip-address "$CURRENT_IP" \
    --only-show-errors \
    2>/dev/null && echo "   ✓ IP added successfully" || echo "   ⚠️  IP already exists or addition failed"

echo "📋 Current firewall rules:"
az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query "networkRuleSet.ipRules[].value" \
    --output table \
    --only-show-errors

echo ""
echo "✅ IP firewall updated! You can now run Terraform commands."
echo ""
echo "💡 Tip: Old IPs accumulate. Clean them up periodically:"
echo "   az storage account network-rule remove --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --ip-address <old-ip>"
