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
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# GitHub OIDC Provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]

  tags = {
    Name        = "github-actions-oidc"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Trust policy for GitHub Actions
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.github_repositories :
        "repo:${var.github_org}/${repo}:*"
      ]
    }
  }
}

# Optional: Restrict to specific branches
data "aws_iam_policy_document" "github_actions_assume_role_main_only" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        for repo in var.github_repositories :
        "repo:${var.github_org}/${repo}:ref:refs/heads/main"
      ]
    }
  }
}

# Read-Only Role
resource "aws_iam_role" "github_readonly" {
  count = var.create_readonly_role ? 1 : 0

  name               = var.readonly_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name        = var.readonly_role_name
    Environment = var.environment
    Purpose     = "GitHub Actions Read-Only Access"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_readonly" {
  count = var.create_readonly_role ? 1 : 0

  role       = aws_iam_role.github_readonly[0].name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# Deploy Role (can create and modify resources)
resource "aws_iam_role" "github_deploy" {
  count = var.create_deploy_role ? 1 : 0

  name               = var.deploy_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Name        = var.deploy_role_name
    Environment = var.environment
    Purpose     = "GitHub Actions Deployment Access"
    ManagedBy   = "terraform"
  }
}

# Custom policy for deployment (adjust permissions as needed)
resource "aws_iam_policy" "github_deploy" {
  count = var.create_deploy_role ? 1 : 0

  name        = "${var.deploy_role_name}-policy"
  description = "Policy for GitHub Actions deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # Terraform state management (if using S3 backend)
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
          
          # EC2 and networking
          "ec2:Describe*",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          
          # IAM (limited)
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          
          # CloudWatch
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          
          # Tags
          "tag:GetResources",
          "tag:TagResources",
          "tag:UntagResources"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          # Allow creating/modifying specific resources
          "ec2:RunInstances",
          "ec2:TerminateInstances",
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupEgress",
          "ec2:CreateKeyPair",
          "ec2:DeleteKeyPair"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = var.aws_region
          }
        }
      }
    ]
  })

  tags = {
    Name        = "${var.deploy_role_name}-policy"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_deploy" {
  count = var.create_deploy_role ? 1 : 0

  role       = aws_iam_role.github_deploy[0].name
  policy_arn = aws_iam_policy.github_deploy[0].arn
}

# Admin Role (restricted to main branch only)
resource "aws_iam_role" "github_admin" {
  count = var.create_admin_role ? 1 : 0

  name               = var.admin_role_name
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role_main_only.json

  tags = {
    Name        = var.admin_role_name
    Environment = var.environment
    Purpose     = "GitHub Actions Admin Access (Main Branch Only)"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "github_admin" {
  count = var.create_admin_role ? 1 : 0

  role       = aws_iam_role.github_admin[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
