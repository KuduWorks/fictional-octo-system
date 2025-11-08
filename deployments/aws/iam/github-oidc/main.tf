# GitHub Actions OIDC Provider for AWS
# This configuration sets up OpenID Connect (OIDC) authentication between GitHub Actions and AWS
# eliminating the need for long-lived AWS credentials stored as GitHub secrets.

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
      Module      = "github-oidc"
      Repository  = "fictional-octo-system"
    }
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}

# Data source to get TLS certificate from GitHub's OIDC provider
# This is used to establish trust between AWS and GitHub
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

# Create the OIDC Identity Provider in AWS IAM
# This tells AWS to trust tokens issued by GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  # GitHub's audience - this is the default for GitHub Actions
  client_id_list = ["sts.amazonaws.com"]

  # Thumbprint from GitHub's TLS certificate
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]

  tags = {
    Name        = "github-actions-oidc-provider"
    Description = "OIDC provider for GitHub Actions authentication"
  }
}

# IAM Role for GitHub Actions - Read-Only Access
# This role can be assumed by GitHub Actions workflows for read-only operations
resource "aws_iam_role" "github_actions_readonly" {
  count = var.create_readonly_role ? 1 : 0

  name        = var.readonly_role_name
  description = "Role for GitHub Actions with read-only access to AWS resources"

  # Trust policy - defines WHO can assume this role
  # In this case: GitHub Actions from specific repositories
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            # Verify the audience claim in the OIDC token
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict to specific GitHub repositories
            # Format: repo:OWNER/REPO:* (allows all branches)
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.github_repositories : "repo:${var.github_org}/${repo}:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = var.readonly_role_name
    Type = "ReadOnly"
  }
}

# Attach ReadOnlyAccess managed policy to the read-only role
resource "aws_iam_role_policy_attachment" "github_readonly" {
  count = var.create_readonly_role ? 1 : 0

  role       = aws_iam_role.github_actions_readonly[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# IAM Role for GitHub Actions - Deployment Access
# This role can deploy infrastructure, write to S3, etc.
resource "aws_iam_role" "github_actions_deploy" {
  count = var.create_deploy_role ? 1 : 0

  name        = var.deploy_role_name
  description = "Role for GitHub Actions with deployment permissions"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.github_repositories : "repo:${var.github_org}/${repo}:*"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name = var.deploy_role_name
    Type = "Deploy"
  }
}

# Custom deployment policy
# Defines specific permissions for deployment operations
resource "aws_iam_role_policy" "github_deploy" {
  count = var.create_deploy_role ? 1 : 0

  name = "github-actions-deploy-policy"
  role = aws_iam_role.github_actions_deploy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::fictional-octo-system-tfstate-${data.aws_caller_identity.current.account_id}",
          "arn:aws:s3:::fictional-octo-system-tfstate-${data.aws_caller_identity.current.account_id}/*"
        ]
      },
      {
        Sid    = "DynamoDBStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.aws_region}:${data.aws_caller_identity.current.account_id}:table/terraform-state-locks"
      },
      {
        Sid    = "IAMPermissions"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:ListRoles",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Permissions"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateTags",
          "ec2:DeleteTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3Permissions"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketEncryption",
          "s3:PutBucketEncryption",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging"
        ]
        Resource = [
          "arn:aws:s3:::*",
          "arn:aws:s3:::*/*"
        ]
      },
      {
        Sid    = "ConfigPermissions"
        Effect = "Allow"
        Action = [
          "config:Put*",
          "config:Get*",
          "config:List*",
          "config:Describe*",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:DeleteConfigRule"
        ]
        Resource = "*"
      },
      {
        Sid    = "BudgetsPermissions"
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "budgets:CreateBudgetAction",
          "budgets:DeleteBudgetAction",
          "budgets:UpdateBudgetAction"
        ]
        Resource = "*"
      },
      {
        Sid    = "SNSPermissions"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListTagsForResource",
          "sns:TagResource",
          "sns:UntagResource"
        ]
        Resource = "*"
      },
      {
        Sid    = "KMSPermissions"
        Effect = "Allow"
        Action = [
          "kms:CreateKey",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy",
          "kms:CreateAlias",
          "kms:DeleteAlias",
          "kms:ListAliases",
          "kms:ListKeys",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion"
        ]
        Resource = "*"
      }
    ]
  })
}

# IAM Role for GitHub Actions - Admin Access (Optional, use with caution)
# This role has broad permissions - only create if absolutely necessary
resource "aws_iam_role" "github_actions_admin" {
  count = var.create_admin_role ? 1 : 0

  name        = var.admin_role_name
  description = "Role for GitHub Actions with administrative access (use with caution)"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
            # More restrictive - require specific branch for admin access
            "token.actions.githubusercontent.com:sub" = [
              for repo in var.github_repositories : "repo:${var.github_org}/${repo}:ref:refs/heads/main"
            ]
          }
        }
      }
    ]
  })

  tags = {
    Name    = var.admin_role_name
    Type    = "Admin"
    Warning = "BroadPermissions"
  }
}

# Attach AdministratorAccess to admin role (if created)
resource "aws_iam_role_policy_attachment" "github_admin" {
  count = var.create_admin_role ? 1 : 0

  role       = aws_iam_role.github_actions_admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
