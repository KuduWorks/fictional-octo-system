#!/bin/bash

# Deploy All Azure Policies Script
# This script deploys all policy categories in the correct order

set -e

# Configuration
SUBSCRIPTION_ID=""
LOCATION="swedencentral"
DEPLOY_TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Deploy All Azure Policies ===${NC}"

# Policy categories in deployment order
POLICY_CATEGORIES=(
    "region-control"
    "network-security"
    "security-baseline" 
    "cost-management"
)

# Function to deploy a single policy category
deploy_policy_category() {
    local category=$1
    local category_path="../$category"
    
    echo -e "${BLUE}=== Deploying $category policies ===${NC}"
    
    if [ ! -d "$category_path" ]; then
        echo -e "${YELLOW}Warning: Directory $category_path not found, skipping...${NC}"
        return 0
    fi
    
    # Check if this is a Terraform-based policy or ARM template
    if [ -f "$category_path/main.tf" ]; then
        # Terraform deployment
        echo -e "${GREEN}Detected Terraform configuration${NC}"
        
        if ! command -v terraform &> /dev/null; then
            echo -e "${RED}Terraform not found. Please install Terraform.${NC}"
            return 1
        fi
        
        cd "$category_path" || return 1
        
        # Check for configuration files
        if [ ! -f "backend.tf" ]; then
            echo -e "${YELLOW}Warning: backend.tf not found. Using local state.${NC}"
            echo -e "${YELLOW}For production, copy backend.tf.example to backend.tf${NC}"
        fi
        
        if [ ! -f "terraform.tfvars" ]; then
            echo -e "${YELLOW}Warning: terraform.tfvars not found. Using defaults.${NC}"
            echo -e "${YELLOW}For custom config, copy terraform.tfvars.example to terraform.tfvars${NC}"
        fi
        
        # Initialize Terraform
        echo -e "${YELLOW}Running terraform init...${NC}"
        if ! terraform init -input=false; then
            echo -e "${RED}Terraform init failed for $category${NC}"
            cd - > /dev/null
            return 1
        fi
        
        # Validate configuration
        echo -e "${YELLOW}Validating Terraform configuration...${NC}"
        if ! terraform validate; then
            echo -e "${RED}Terraform validation failed for $category${NC}"
            cd - > /dev/null
            return 1
        fi
        
        # Plan
        echo -e "${YELLOW}Running terraform plan...${NC}"
        if ! terraform plan -out=tfplan -input=false; then
            echo -e "${RED}Terraform plan failed for $category${NC}"
            cd - > /dev/null
            return 1
        fi
        
        # Apply
        echo -e "${BLUE}Deploying with Terraform...${NC}"
        if terraform apply -input=false tfplan; then
            echo -e "${GREEN}✅ $category policies deployed successfully!${NC}"
            
            # Show outputs
            echo -e "${BLUE}Terraform outputs for $category:${NC}"
            terraform output || echo "No outputs available"
            
            cd - > /dev/null
            return 0
        else
            echo -e "${RED}❌ Terraform apply failed for $category${NC}"
            cd - > /dev/null
            return 1
        fi
        
    elif [ -f "$category_path/arm-template.json" ]; then
        # ARM template deployment
        echo -e "${GREEN}Detected ARM template${NC}"
        
        # Check for parameters file
        local params_file="$category_path/arm-template.parameters.json"
        local deploy_params=""
        
        if [ -f "$params_file" ]; then
            deploy_params="--parameters $params_file"
            echo -e "${GREEN}Using parameters file: $params_file${NC}"
        else
            echo -e "${YELLOW}No parameters file found, using defaults${NC}"
        fi
        
        # Validate template
        echo -e "${YELLOW}Validating $category ARM template...${NC}"
        if az deployment sub validate \
            --location "$LOCATION" \
            --template-file "$category_path/arm-template.json" \
            $deploy_params \
            --only-show-errors; then
            echo -e "${GREEN}Template validation successful!${NC}"
        else
            echo -e "${RED}Template validation failed for $category${NC}"
            return 1
        fi
        
        # Deploy
        local deployment_name="azure-policy-$category-$DEPLOY_TIMESTAMP"
        echo -e "${BLUE}Deploying $category policies...${NC}"
        
        local deployment_result=$(az deployment sub create \
            --location "$LOCATION" \
            --template-file "$category_path/arm-template.json" \
            $deploy_params \
            --name "$deployment_name" \
            --query "properties.provisioningState" -o tsv)
        
        if [ "$deployment_result" = "Succeeded" ]; then
            echo -e "${GREEN}✅ $category policies deployed successfully!${NC}"
            
            # Show outputs if available
            echo -e "${BLUE}Deployment outputs for $category:${NC}"
            az deployment sub show \
                --name "$deployment_name" \
                --query "properties.outputs" \
                --output table 2>/dev/null || echo "No outputs available"
                
            return 0
        else
            echo -e "${RED}❌ $category deployment failed with status: $deployment_result${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}Warning: No deployment configuration found in $category_path, skipping...${NC}"
        return 0
    fi
}

# Function to validate all policies after deployment
validate_deployment() {
    echo -e "${BLUE}=== Validating Policy Deployment ===${NC}"
    
    # List all policy assignments
    echo -e "${BLUE}Policy assignments created:${NC}"
    az policy assignment list \
        --query "[?contains(name, 'region') || contains(name, 'security') || contains(name, 'cost') || contains(name, 'nsg-required') || contains(name, 'deny-vm-public-ip')].{Name:name, DisplayName:displayName, Scope:scope, EnforcementMode:enforcementMode}" \
        --output table
    
    # List policy definitions
    echo -e "${BLUE}Custom policy definitions created:${NC}"
    az policy definition list \
        --query "[?policyType=='Custom'].{Name:name, DisplayName:displayName, Mode:mode}" \
        --output table
    
    # List policy set definitions (initiatives)
    echo -e "${BLUE}Policy initiatives created:${NC}"
    az policy set-definition list \
        --query "[?policyType=='Custom'].{Name:name, DisplayName:displayName}" \
        --output table
}

# Function to test policy enforcement
test_policies() {
    echo -e "${BLUE}=== Testing Policy Enforcement ===${NC}"
    
    # Test region control
    echo -e "${YELLOW}Testing region control policy...${NC}"
    if az group create --name "test-region-policy" --location "eastus" 2>/dev/null; then
        echo -e "${RED}⚠️  Region policy test failed - resource group created in non-allowed region${NC}"
        az group delete --name "test-region-policy" --yes --no-wait 2>/dev/null
    else
        echo -e "${GREEN}✅ Region policy working - blocked deployment to non-allowed region${NC}"
    fi
    
    # Test allowed region
    echo -e "${YELLOW}Testing allowed region...${NC}"
    if az group create --name "test-allowed-region" --location "swedencentral" 2>/dev/null; then
        echo -e "${GREEN}✅ Allowed region working - resource group created successfully${NC}"
        az group delete --name "test-allowed-region" --yes --no-wait 2>/dev/null
    else
        echo -e "${RED}⚠️  Issue with allowed region - could not create resource group${NC}"
    fi
}

# Main execution
main() {
    # Check prerequisites
    if ! command -v az &> /dev/null; then
        echo -e "${RED}Error: Azure CLI is not installed${NC}"
        exit 1
    fi
    
    if ! az account show --only-show-errors &> /dev/null; then
        echo -e "${YELLOW}Please log in to Azure...${NC}"
        az login
    fi
    
    # Get subscription info
    if [ -z "$SUBSCRIPTION_ID" ]; then
        SUBSCRIPTION_ID=$(az account show --query id -o tsv --only-show-errors)
    fi
    
    az account set --subscription "$SUBSCRIPTION_ID"
    echo -e "${BLUE}Deploying to subscription: $SUBSCRIPTION_ID${NC}"
    
    # Ask for confirmation
    echo -e "${YELLOW}This will deploy all Azure policy categories. Continue? (y/N):${NC}"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deployment cancelled${NC}"
        exit 0
    fi
    
    # Deploy each policy category
    local failed_categories=()
    
    for category in "${POLICY_CATEGORIES[@]}"; do
        if ! deploy_policy_category "$category"; then
            failed_categories+=("$category")
        fi
        echo # Add spacing between deployments
    done
    
    # Report results
    if [ ${#failed_categories[@]} -eq 0 ]; then
        echo -e "${GREEN}🎉 All policy categories deployed successfully!${NC}"
        
        # Wait for policies to propagate
        echo -e "${YELLOW}Waiting 30 seconds for policies to propagate...${NC}"
        sleep 30
        
        validate_deployment
        
        # Ask if user wants to test
        echo -e "${YELLOW}Would you like to test policy enforcement? (y/N):${NC}"
        read -r test_response
        if [[ "$test_response" =~ ^[Yy]$ ]]; then
            test_policies
        fi
        
    else
        echo -e "${RED}❌ Some deployments failed:${NC}"
        for category in "${failed_categories[@]}"; do
            echo -e "${RED}  - $category${NC}"
        done
        exit 1
    fi
    
    echo -e "${BLUE}=== Deployment Complete ===${NC}"
    echo -e "${GREEN}View your policies in the Azure Portal:${NC}"
    echo -e "${BLUE}https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyMenuBlade/Overview${NC}"
}

# Run main function
main "$@"