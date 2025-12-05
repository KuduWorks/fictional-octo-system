terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Module      = "organization-protection"
      Purpose     = "Organization-Governance"
    }
  }
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}

# Data source to get organization information
data "aws_organizations_organization" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

# ============================================================================
# SERVICE CONTROL POLICY: ORGANIZATION PROTECTION
# ============================================================================

resource "aws_organizations_policy" "organization_protection" {
  name        = "OrganizationProtection"
  description = "Allows read-only organization access but prevents modifications from member accounts"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowOrganizationReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "organizations:Describe*",
          "organizations:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyOrganizationModifications"
        Effect = "Deny"
        Action = [
          "organizations:AcceptHandshake",
          "organizations:AttachPolicy",
          "organizations:CancelHandshake",
          "organizations:CreateAccount",
          "organizations:CreateGovCloudAccount",
          "organizations:CreateOrganization",
          "organizations:CreateOrganizationalUnit",
          "organizations:CreatePolicy",
          "organizations:DeclineHandshake",
          "organizations:DeleteOrganization",
          "organizations:DeleteOrganizationalUnit",
          "organizations:DeletePolicy",
          "organizations:DeregisterDelegatedAdministrator",
          "organizations:DetachPolicy",
          "organizations:DisableAWSServiceAccess",
          "organizations:DisablePolicyType",
          "organizations:EnableAWSServiceAccess",
          "organizations:EnableAllFeatures",
          "organizations:EnablePolicyType",
          "organizations:InviteAccountToOrganization",
          "organizations:LeaveOrganization",
          "organizations:MoveAccount",
          "organizations:RegisterDelegatedAdministrator",
          "organizations:RemoveAccountFromOrganization",
          "organizations:UpdateOrganizationalUnit",
          "organizations:UpdatePolicy"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:PrincipalAccount" = [var.management_account_id]
          }
        }
      }
    ]
  })
}

# Attach SCP to organization root
resource "aws_organizations_policy_attachment" "organization_protection_attachment" {
  policy_id = aws_organizations_policy.organization_protection.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}
