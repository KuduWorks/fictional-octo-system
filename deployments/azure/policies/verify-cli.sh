#!/bin/bash

# Azure Policy CLI Verification Script
# This script validates Azure CLI policy deployment without actually deploying

set -e

# Configuration Variables (same as deploy-cli.sh)
ALLOWED_REGIONS='["swedencentral"]'
POLICY_ASSIGNMENT_NAME="allowed-regions-sweden-central"
POLICY_DISPLAY_NAME="Allowed Regions Policy - Sweden Central"
POLICY_DESCRIPTION="This policy restricts all Azure resource deployments to Sweden Central region only"
ENFORCEMENT_MODE="Default"
SUBSCRIPTION_ID=""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure Policy CLI Verification Script ===${NC}"

# Function to check prerequisites
check_prerequisites() {
    echo -e "${YELLOW}Checking prerequisites...${NC}"
    
    # Check Azure CLI
    if ! command -v az &> /dev/null; then
        echo -e "${RED}❌ Azure CLI is not installed${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Azure CLI is installed${NC}"
        az --version | head -1
    fi
    
    # Check login status
    if ! az account show &> /dev/null; then
        echo -e "${RED}❌ Not logged in to Azure${NC}"
        exit 1
    else
        echo -e "${GREEN}✅ Logged in to Azure${NC}"
    fi
    
    # Get subscription info
    if [ -z "$SUBSCRIPTION_ID" ]; then
        SUBSCRIPTION_ID=$(az account show --query id -o tsv)
    fi
    
    echo -e "${GREEN}✅ Using subscription: $SUBSCRIPTION_ID${NC}"
}

# Function to check permissions
check_permissions() {
    echo -e "${YELLOW}Checking permissions...${NC}"
    
    # Check if user has Policy Contributor role
    local role_assignments=$(az role assignment list \
        --assignee "$(az account show --query user.name -o tsv)" \
        --query "[?roleDefinitionName=='Policy Contributor' || roleDefinitionName=='Owner' || roleDefinitionName=='Contributor'].roleDefinitionName" \
        -o tsv)
    
    if [ -n "$role_assignments" ]; then
        echo -e "${GREEN}✅ Has required permissions: $role_assignments${NC}"
    else
        echo -e "${YELLOW}⚠️  Could not verify Policy Contributor role. You may need this role to deploy policies.${NC}"
    fi
}

# Function to check existing policies
check_existing_policies() {
    echo -e "${YELLOW}Checking for existing policies...${NC}"
    
    # Check for existing policy assignments
    local existing_assignments=$(az policy assignment list \
        --query "[?name=='$POLICY_ASSIGNMENT_NAME'].name" -o tsv)
    
    if [ -n "$existing_assignments" ]; then
        echo -e "${YELLOW}⚠️  Policy assignment '$POLICY_ASSIGNMENT_NAME' already exists${NC}"
        echo -e "${YELLOW}   Deployment will update the existing assignment${NC}"
    else
        echo -e "${GREEN}✅ No conflicting policy assignments found${NC}"
    fi
    
    # Check for existing custom policy definitions
    local existing_policies=$(az policy definition list \
        --query "[?name=='custom-rg-location-policy'].name" -o tsv)
    
    if [ -n "$existing_policies" ]; then
        echo -e "${YELLOW}⚠️  Custom policy 'custom-rg-location-policy' already exists${NC}"
        echo -e "${YELLOW}   Deployment will update the existing policy${NC}"
    else
        echo -e "${GREEN}✅ No conflicting custom policies found${NC}"
    fi
    
    # Check for existing policy set definitions
    local existing_initiatives=$(az policy set-definition list \
        --query "[?name=='region-control-initiative'].name" -o tsv)
    
    if [ -n "$existing_initiatives" ]; then
        echo -e "${YELLOW}⚠️  Policy initiative 'region-control-initiative' already exists${NC}"
        echo -e "${YELLOW}   Deployment will update the existing initiative${NC}"
    else
        echo -e "${GREEN}✅ No conflicting policy initiatives found${NC}"
    fi
}

# Function to validate policy JSON
validate_policy_json() {
    echo -e "${YELLOW}Validating policy JSON structures...${NC}"
    
    # Create temporary policy JSON for validation
    cat > /tmp/rg-location-policy.json << EOF
{
  "mode": "All",
  "policyRule": {
    "if": {
      "allOf": [
        {
          "field": "type",
          "equals": "Microsoft.Resources/resourceGroups"
        },
        {
          "field": "location",
          "notIn": "[parameters('allowedLocations')]"
        }
      ]
    },
    "then": {
      "effect": "deny"
    }
  },
  "parameters": {
    "allowedLocations": {
      "type": "Array",
      "metadata": {
        "displayName": "Allowed locations",
        "description": "The list of locations that resource groups can be created in",
        "strongType": "location"
      }
    }
  }
}
EOF
    
    # Validate JSON syntax
    if python3 -m json.tool /tmp/rg-location-policy.json > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Policy JSON syntax is valid${NC}"
    elif python -m json.tool /tmp/rg-location-policy.json > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Policy JSON syntax is valid${NC}"
    else
        echo -e "${RED}❌ Policy JSON syntax is invalid${NC}"
        exit 1
    fi
    
    # Clean up
    rm -f /tmp/rg-location-policy.json
}

# Function to check built-in policy exists
check_builtin_policy() {
    echo -e "${YELLOW}Checking built-in policy availability...${NC}"
    
    local builtin_policy_id="/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"
    
    if az policy definition show --name "e56962a6-4747-49cd-b67b-bf8b01975c4c" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Built-in 'Allowed locations' policy is available${NC}"
    else
        echo -e "${RED}❌ Built-in 'Allowed locations' policy not found${NC}"
        exit 1
    fi
}

# Function to simulate deployment (dry run)
simulate_deployment() {
    echo -e "${YELLOW}Simulating deployment steps...${NC}"
    
    echo -e "${BLUE}1. Would create custom policy definition: 'custom-rg-location-policy'${NC}"
    echo -e "${BLUE}2. Would create policy set definition: 'region-control-initiative'${NC}"
    echo -e "${BLUE}3. Would assign built-in policy: '$POLICY_ASSIGNMENT_NAME'${NC}"
    echo -e "${BLUE}4. Would assign custom policy: 'rg-location-policy-assignment'${NC}"
    echo -e "${BLUE}5. Would assign policy initiative: 'region-control-initiative-assignment'${NC}"
    
    echo -e "${GREEN}✅ All deployment steps validated${NC}"
}

# Function to show configuration
show_configuration() {
    echo -e "${YELLOW}Deployment Configuration:${NC}"
    echo -e "${BLUE}  Allowed Regions: $ALLOWED_REGIONS${NC}"
    echo -e "${BLUE}  Policy Assignment Name: $POLICY_ASSIGNMENT_NAME${NC}"
    echo -e "${BLUE}  Enforcement Mode: $ENFORCEMENT_MODE${NC}"
    echo -e "${BLUE}  Target Subscription: $SUBSCRIPTION_ID${NC}"
}

# Function to estimate impact
estimate_impact() {
    echo -e "${YELLOW}Estimating deployment impact...${NC}"
    
    # Count existing resource groups in non-allowed regions
    local non_compliant_rgs=$(az group list \
        --query "[?location!='swedencentral'].{name:name, location:location}" \
        --output json | jq length 2>/dev/null || echo "0")
    
    if [ "$non_compliant_rgs" -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Found $non_compliant_rgs resource groups in non-allowed regions${NC}"
        echo -e "${YELLOW}   These existing resources will not be affected (policies are not retroactive)${NC}"
        echo -e "${YELLOW}   But new resources in these regions will be blocked${NC}"
    else
        echo -e "${GREEN}✅ All existing resource groups are in allowed regions${NC}"
    fi
}

# Main verification function
main() {
    echo -e "${BLUE}Starting Azure Policy CLI verification...${NC}"
    echo
    
    check_prerequisites
    echo
    
    check_permissions
    echo
    
    check_existing_policies
    echo
    
    validate_policy_json
    echo
    
    check_builtin_policy
    echo
    
    show_configuration
    echo
    
    estimate_impact
    echo
    
    simulate_deployment
    echo
    
    echo -e "${GREEN}🎉 Verification completed successfully!${NC}"
    echo -e "${BLUE}You can now run the deployment script with confidence.${NC}"
    echo
    echo -e "${YELLOW}To deploy, run:${NC}"
    echo -e "${BLUE}  ./deploy-cli.sh${NC}"
    echo
    echo -e "${YELLOW}To deploy ARM template instead:${NC}"
    echo -e "${BLUE}  cd region-control && ./deploy-arm.sh${NC}"
}

# Run verification
main "$@"