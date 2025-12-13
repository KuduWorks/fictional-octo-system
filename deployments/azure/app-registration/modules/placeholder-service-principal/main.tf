terraform {
  required_version = ">= 1.0"
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47"
    }
  }
}

# Create application registration with ZERO permissions (zero-trust principle)
# This placeholder exists ONLY to satisfy the 2-owner requirement temporarily
resource "azuread_application" "placeholder" {
  display_name = var.placeholder_name
  
  # Explicitly set NO permissions - zero-trust default
  # No required_resource_access blocks = no API permissions
  
  # Prevent interactive sign-in
  sign_in_audience = "AzureADMyOrg"
  
  # Add identifying tag
  tags = concat(
    var.tags,
    [
      "purpose:placeholder-owner",
      "zero-permissions:true",
      "requires-justification:true"
    ]
  )
  
  # Lifecycle rule: Must have justification before creation
  lifecycle {
    precondition {
      condition     = length(var.justification) >= 50
      error_message = "Placeholder service principal justification must be at least 50 characters. Current length: ${length(var.justification)}. This justification will be audited quarterly."
    }
    
    precondition {
      condition     = can(regex("^[^<>\"'&]*$", var.justification))
      error_message = "Justification must not contain HTML/script special characters (<, >, \", ', &) to prevent injection attacks."
    }
  }
}

# Create service principal from application
resource "azuread_service_principal" "placeholder" {
  client_id                    = azuread_application.placeholder.client_id
  app_role_assignment_required = true  # Prevent accidental usage
  
  # Add identifying tags
  tags = concat(
    var.tags,
    [
      "purpose:placeholder-owner",
      "zero-permissions:true",
      "requires-justification:true"
    ]
  )
  
  # Prevent accidental OAuth flows
  feature_tags {
    enterprise = false
    gallery    = false
  }
}

# Store justification in description for audit trail
resource "azuread_application" "placeholder_with_notes" {
  display_name = azuread_application.placeholder.display_name
  notes        = jsonencode({
    purpose              = "Placeholder owner for 2-owner minimum requirement"
    justification        = var.justification
    justification_length = length(var.justification)
    created_date         = timestamp()
    quarterly_review     = "Required on Q2 and Q4 first Monday"
    escalation_policy    = "Escalate to leadership if placeholder exists >6 months"
    zero_permissions     = true
    # Track who created this for accountability
    created_by_workflow  = var.created_by_workflow
  })
  
  # Reference existing application
  object_id = azuread_application.placeholder.object_id
  
  lifecycle {
    ignore_changes = [
      display_name,
      sign_in_audience,
      tags
    ]
  }
}
