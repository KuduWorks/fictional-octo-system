#!/bin/bash
# Script to update storage account firewall with current IP before Terraform operations

set -e

STORAGE_ACCOUNT="tfstate20251013"
RESOURCE_GROUP="rg-tfstate"

echo "🔍 Getting current IP address..."
CURRENT_IP=$(curl -s ifconfig.me)
if [[ -z "$CURRENT_IP" ]]; then
    echo "❌ Failed to retrieve current IP address. Please check your network connection and try again."
    exit 1
fi
echo "📍 Current IP: $CURRENT_IP"

echo "🔐 Checking Azure authentication..."
az account show > /dev/null 2>&1 || {
    echo "❌ Not logged in to Azure. Running 'az login'..."
    az login
}

echo "➕ Adding current IP to storage account firewall..."
az storage account network-rule add \
    --account-name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --ip-address "$CURRENT_IP" \
    2>/dev/null || echo "⚠️  IP already exists or addition failed"

echo "📋 Current firewall rules:"
az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query "networkRuleSet.ipRules[].value" \
    --output table

echo ""
echo "✅ IP firewall updated! You can now run Terraform commands."
echo ""
echo "💡 Tip: Old IPs accumulate. Clean them up periodically:"
echo "   az storage account network-rule remove --account-name $STORAGE_ACCOUNT --resource-group $RESOURCE_GROUP --ip-address <old-ip>"
