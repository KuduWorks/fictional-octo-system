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
  
  # This will assume a role in the member account
  assume_role {
    role_arn = "arn:aws:iam::${var.member_account_id}:role/OrganizationAccountAccessRole"
  }
}

# ============================================================================
# CROSS-ACCOUNT TESTING ROLE
# ============================================================================

# This role allows the management account to assume into the member account
# for testing SCPs
resource "aws_iam_role" "cross_account_test" {
  name        = "CrossAccountTestRole"
  description = "Role for testing SCPs from management account"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.management_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = {
    Purpose     = "SCP Testing"
    Environment = var.environment
  }
}

# Attach AdministratorAccess for full testing capabilities
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.cross_account_test.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# CROSS-ACCOUNT ADMIN ROLE
# ============================================================================

# This role allows the management account to assume into the member account
# for full admin capabilities
resource "aws_iam_role" "cross_account_admin" {
  name = "CrossAccountAdminRole"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.trusted_account_id}:root"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  tags = var.tags
}

# Attach AdministratorAccess for full admin capabilities
resource "aws_iam_role_policy_attachment" "cross_account_admin" {
  role       = aws_iam_role.cross_account_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "test_role_arn" {
  description = "ARN of the cross-account test role to assume (for SCP testing)"
  value       = aws_iam_role.cross_account_test.arn
}

output "admin_role_arn" {
  description = "ARN of the cross-account admin role to assume (for full admin capabilities)"
  value       = aws_iam_role.cross_account_admin.arn
}

output "test_assume_role_command" {
  description = "Command to assume the cross-account test role (for SCP testing)"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.cross_account_test.arn} --role-session-name CrossAccountTestSession"
  sensitive   = true
}

output "admin_assume_role_command" {
  description = "Command to assume the cross-account admin role (for full admin capabilities)"
  value       = "aws sts assume-role --role-arn ${aws_iam_role.cross_account_admin.arn} --role-session-name CrossAccountAdminSession"
  sensitive   = true
}

output "test_instructions" {
  description = "Instructions for testing the cross-account test role (for SCP testing)"
  value       = <<-EOT
    To test the cross-account test role:
    1. Run: aws sts assume-role --role-arn ${aws_iam_role.cross_account_test.arn} --role-session-name TestSession
    2. Export the credentials from the response
    3. Test access to the target account
  EOT
  sensitive   = true
}

output "admin_instructions" {
  description = "Instructions for assuming the cross-account admin role (for full admin capabilities)"
  value       = <<-EOT
    To assume the cross-account admin role:
    1. Run: aws sts assume-role --role-arn ${aws_iam_role.cross_account_admin.arn} --role-session-name AdminSession
    2. Export the credentials from the response
    3. Test admin access to the target account
  EOT
  sensitive   = true
}
