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
      Module      = "region-control"
      Purpose     = "Regional-Compliance"
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
# SERVICE CONTROL POLICY: REGION RESTRICTION
# ============================================================================

resource "aws_organizations_policy" "region_restriction" {
  name        = "RegionRestriction"
  description = "Restricts AWS operations to allowed regions only - Geographic compliance control"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyOperationsOutsideAllowedRegions"
        Effect   = "Deny"
        NotAction = [
          # Global services that don't support regions
          "iam:*",
          "organizations:*",
          "route53:*",
          "cloudfront:*",
          "globalaccelerator:*",
          "shield:*",
          "waf:*",
          "waf-regional:*",
          "support:*",
          "trustedadvisor:*",
          "ce:*",
          "budgets:*",
          "aws-portal:*",
          "cur:*",
          "account:*",
          "billing:*",
          "tax:*",
          "purchase-orders:*",
          "consolidatedbilling:*",
          "freetier:*",
          "invoicing:*",
          "payments:*",
          "s3:GetAccountPublicAccessBlock",
          "s3:PutAccountPublicAccessBlock",
          "s3:GetBucketLocation",
          "s3:ListAllMyBuckets"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = var.allowed_regions
          }
        }
      },
      {
        Sid    = "DenyS3BucketActionsOutsideAllowedRegions"
        Effect = "Deny"
        Action = [
          "s3:CreateBucket"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:LocationConstraint" = var.allowed_regions
          }
        }
      },
      {
        Sid    = "DenyS3BucketActionsInUsEast1"
        Effect = "Deny"
        Action = [
          "s3:CreateBucket"
        ]
        Resource = "*"
        Condition = {
          StringEqualsIfExists = {
            "s3:LocationConstraint" = ""
          }
        }
      }
    ]
  })
}

# Attach SCP to organization root
resource "aws_organizations_policy_attachment" "region_restriction_attachment" {
  policy_id = aws_organizations_policy.region_restriction.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}
