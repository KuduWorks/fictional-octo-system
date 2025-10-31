#!/bin/bash
# Helper script to find Microsoft Graph permission IDs

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║        Microsoft Graph Permission Lookup Tool                  ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Check if az CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed."
    echo "   Install from: https://aka.ms/InstallAzureCLIDeb"
    exit 1
fi

# Check if logged in
if ! az account show &> /dev/null; then
    echo "❌ Not logged in to Azure CLI"
    echo "   Run: az login"
    exit 1
fi

echo "✓ Azure CLI authenticated"
echo ""

# Function to search permissions
search_permissions() {
    local search_term=$1
    echo "🔍 Searching for permissions matching: $search_term"
    echo ""
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "DELEGATED PERMISSIONS (Scope - acts on behalf of user)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    az ad sp show --id 00000003-0000-0000-c000-000000000000 \
        --query "oauth2PermissionScopes[?contains(value, '${search_term}')].{ID:id, Name:value, AdminConsent:adminConsentDescription}" \
        --output table 2>/dev/null || echo "No delegated permissions found"
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "APPLICATION PERMISSIONS (Role - acts as the app itself)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    az ad sp show --id 00000003-0000-0000-c000-000000000000 \
        --query "appRoles[?contains(value, '${search_term}')].{ID:id, Name:value, Description:description}" \
        --output table 2>/dev/null || echo "No application permissions found"
}

# Function to generate Terraform snippet
generate_terraform() {
    local perm_id=$1
    local perm_type=$2
    local perm_value=$3
    
    echo ""
    echo "📝 Terraform snippet:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat <<EOF
{
  id    = "${perm_id}"
  type  = "${perm_type}"  # "Scope" for delegated, "Role" for application
  value = "${perm_value}"
}
EOF
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main menu
while true; do
    echo ""
    echo "Options:"
    echo "  1) Search by permission name (e.g., User, Mail, Directory)"
    echo "  2) List all delegated permissions"
    echo "  3) List all application permissions"
    echo "  4) Get details for specific permission ID"
    echo "  5) Generate Terraform snippet"
    echo "  6) Exit"
    echo ""
    read -p "Enter your choice (1-6): " choice
    
    case $choice in
        1)
            echo ""
            read -p "Enter search term (e.g., User, Mail, Group): " search_term
            search_permissions "$search_term"
            ;;
        2)
            echo ""
            echo "📋 All Delegated Permissions (Scopes):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            az ad sp show --id 00000003-0000-0000-c000-000000000000 \
                --query "oauth2PermissionScopes[].{ID:id, Name:value, RequiresAdmin:isEnabled}" \
                --output table | head -50
            echo ""
            echo "(Showing first 50 results. Use option 1 to search specific permissions)"
            ;;
        3)
            echo ""
            echo "📋 All Application Permissions (Roles):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            az ad sp show --id 00000003-0000-0000-c000-000000000000 \
                --query "appRoles[].{ID:id, Name:value, Enabled:isEnabled}" \
                --output table | head -50
            echo ""
            echo "(Showing first 50 results. Use option 1 to search specific permissions)"
            ;;
        4)
            echo ""
            read -p "Enter permission ID (GUID): " perm_id
            echo ""
            echo "🔍 Searching for permission ID: $perm_id"
            echo ""
            
            # Check in delegated permissions
            result=$(az ad sp show --id 00000003-0000-0000-c000-000000000000 \
                --query "oauth2PermissionScopes[?id=='${perm_id}'].{ID:id, Name:value, Type:'Scope', Admin:adminConsentDescription, User:userConsentDescription}" \
                --output json 2>/dev/null)
            
            if [ "$result" != "[]" ]; then
                echo "$result" | jq -r '.[] | "ID:          \(.ID)\nName:        \(.Name)\nType:        \(.Type)\nAdmin Desc:  \(.Admin)\nUser Desc:   \(.User)"'
            else
                # Check in application permissions
                result=$(az ad sp show --id 00000003-0000-0000-c000-000000000000 \
                    --query "appRoles[?id=='${perm_id}'].{ID:id, Name:value, Type:'Role', Description:description}" \
                    --output json 2>/dev/null)
                
                if [ "$result" != "[]" ]; then
                    echo "$result" | jq -r '.[] | "ID:          \(.ID)\nName:        \(.Name)\nType:        \(.Type)\nDescription: \(.Description)"'
                else
                    echo "❌ Permission ID not found"
                fi
            fi
            ;;
        5)
            echo ""
            read -p "Enter permission ID: " perm_id
            read -p "Enter permission type (Scope or Role): " perm_type
            read -p "Enter permission name (e.g., User.Read): " perm_value
            generate_terraform "$perm_id" "$perm_type" "$perm_value"
            ;;
        6)
            echo ""
            echo "👋 Goodbye!"
            exit 0
            ;;
        *)
            echo "❌ Invalid choice. Please enter 1-6."
            ;;
    esac
done
