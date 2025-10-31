#!/bin/bash
# Helper script to find your Object ID for RBAC assignments

set -e

echo "🔍 Azure Key Vault RBAC Helper"
echo "================================"
echo ""

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed"
    echo "Install from: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure CLI"
    echo "Run: az login"
    exit 1
fi

echo "✅ Azure CLI is installed and you're logged in"
echo ""

# Get current user info
echo "📋 Your Identity:"
echo "----------------"
MY_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
MY_EMAIL=$(az ad signed-in-user show --query userPrincipalName -o tsv)
MY_NAME=$(az ad signed-in-user show --query displayName -o tsv)

echo "Name:      $MY_NAME"
echo "Email:     $MY_EMAIL"
echo "Object ID: $MY_OBJECT_ID"
echo ""

# Get current subscription
SUB_NAME=$(az account show --query name -o tsv)
SUB_ID=$(az account show --query id -o tsv)

echo "📍 Current Subscription:"
echo "------------------------"
echo "Name: $SUB_NAME"
echo "ID:   $SUB_ID"
echo ""

# Function to get object ID
get_object_id() {
    local type=$1
    local identifier=$2
    
    case $type in
        user)
            az ad user show --id "$identifier" --query id -o tsv 2>/dev/null
            ;;
        group)
            az ad group show --group "$identifier" --query id -o tsv 2>/dev/null
            ;;
        sp)
            az ad sp list --display-name "$identifier" --query "[0].id" -o tsv 2>/dev/null
            ;;
        app)
            az ad app show --id "$identifier" --query id -o tsv 2>/dev/null
            ;;
        *)
            echo ""
            ;;
    esac
}

# Interactive mode
echo "🔎 Look up Object IDs:"
echo "---------------------"
echo "1) User (by email)"
echo "2) Group (by name)"
echo "3) Service Principal (by name)"
echo "4) Managed Identity (by resource)"
echo "5) Exit"
echo ""

read -p "Select option (1-5): " option

case $option in
    1)
        read -p "Enter user email: " email
        obj_id=$(get_object_id user "$email")
        if [ -n "$obj_id" ]; then
            echo "✅ Object ID: $obj_id"
            echo ""
            echo "Add to terraform.tfvars:"
            echo 'secrets_user_principal_ids = ["'$obj_id'"]'
        else
            echo "❌ User not found"
        fi
        ;;
    2)
        read -p "Enter group name: " group_name
        obj_id=$(get_object_id group "$group_name")
        if [ -n "$obj_id" ]; then
            echo "✅ Object ID: $obj_id"
            echo ""
            echo "Add to terraform.tfvars:"
            echo 'secrets_user_principal_ids = ["'$obj_id'"]'
        else
            echo "❌ Group not found"
        fi
        ;;
    3)
        read -p "Enter service principal name: " sp_name
        obj_id=$(get_object_id sp "$sp_name")
        if [ -n "$obj_id" ]; then
            echo "✅ Object ID: $obj_id"
            echo ""
            echo "Add to terraform.tfvars:"
            echo 'secrets_user_principal_ids = ["'$obj_id'"]'
        else
            echo "❌ Service Principal not found"
        fi
        ;;
    4)
        read -p "Enter resource name: " resource_name
        read -p "Enter resource group: " rg_name
        read -p "Resource type (webapp/functionapp/vm): " resource_type
        
        case $resource_type in
            webapp)
                obj_id=$(az webapp identity show --name "$resource_name" --resource-group "$rg_name" --query principalId -o tsv 2>/dev/null)
                ;;
            functionapp)
                obj_id=$(az functionapp identity show --name "$resource_name" --resource-group "$rg_name" --query principalId -o tsv 2>/dev/null)
                ;;
            vm)
                obj_id=$(az vm identity show --name "$resource_name" --resource-group "$rg_name" --query principalId -o tsv 2>/dev/null)
                ;;
            *)
                echo "❌ Unknown resource type"
                exit 1
                ;;
        esac
        
        if [ -n "$obj_id" ]; then
            echo "✅ Managed Identity Object ID: $obj_id"
            echo ""
            echo "Add to terraform.tfvars:"
            echo 'secrets_user_principal_ids = ["'$obj_id'"]'
        else
            echo "❌ Resource not found or managed identity not enabled"
        fi
        ;;
    5)
        echo "👋 Goodbye!"
        exit 0
        ;;
    *)
        echo "❌ Invalid option"
        exit 1
        ;;
esac

echo ""
echo "💡 Pro Tip: You can also get Object IDs from Azure Portal:"
echo "   Azure AD → Users/Groups/Enterprise Applications → Copy Object ID"
