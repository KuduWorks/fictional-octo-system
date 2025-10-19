# Terraform Variables for Azure Policy Deployment

# List of allowed Azure regions
allowed_regions = ["swedencentral"]

# Policy assignment name
policy_assignment_name = "allowed-regions-sweden-central-tf"

# Display name for the policy assignment
policy_assignment_display_name = "Allowed Regions Policy - Sweden Central (Terraform)"

# Enforcement mode: "Default" or "DoNotEnforce"
enforcement_mode = "Default"

# Optional: specify subscription ID (if not using default)
# subscription_id = "your-subscription-id-here"
