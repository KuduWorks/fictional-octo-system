terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Store this module's state in S3
  # ⚠️ IMPORTANT: Backend configuration does not support variables.
  # You MUST manually update the bucket name below with your AWS account ID
  # before migrating state to S3.
  #
  # Steps:
  # 1. First run: Comment out this entire backend block and run `terraform init`
  #    and `terraform apply` to create the S3 bucket (state stored locally).
  # 2. After bucket creation: Update the bucket name below to match your
  #    actual bucket name (which includes your AWS account ID).
  # 3. Uncomment this block and run `terraform init -migrate-state` to move
  #    the local state to S3.
  #
  # Example bucket name format: fictional-octo-system-tfstate-<YOUR-ACCOUNT-ID>
  backend "s3" {
    bucket         = "fictional-octo-system-tfstate-494367313227"
    key            = "bootstrap/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}

provider "aws" {
  region = var.aws_region
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  bucket_name = var.state_bucket_name != "" ? var.state_bucket_name : "fictional-octo-system-tfstate-${local.account_id}"
}

# S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = local.bucket_name

  tags = {
    Name        = "Terraform State Storage"
    Purpose     = "terraform-state"
    ManagedBy   = "Terraform"
    Environment = "global"
  }
}

# Enable versioning for state recovery
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket policy to enforce HTTPS-only access
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyInsecureTransport"
        Effect = "Deny"
        Principal = "*"
        Action   = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}


# Enable logging (optional but recommended)
resource "aws_s3_bucket" "terraform_state_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = "${local.bucket_name}-logs"

  tags = {
    Name      = "Terraform State Logs"
    Purpose   = "terraform-state-logs"
    ManagedBy = "Terraform"
  }
}

resource "aws_s3_bucket_logging" "terraform_state" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.terraform_state_logs[0].id
  target_prefix = "state-access-logs/"
}

# Enable versioning for logs bucket
resource "aws_s3_bucket_versioning" "terraform_state_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.terraform_state_logs[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable encryption for logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.terraform_state_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access for logs bucket
resource "aws_s3_bucket_public_access_block" "terraform_state_logs" {
  count  = var.enable_logging ? 1 : 0
  bucket = aws_s3_bucket.terraform_state_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rule to manage old versions
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    filter {}  # Add this empty filter block

    noncurrent_version_expiration {
      noncurrent_days = var.state_version_retention_days
    }
  }
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"  # Scales automatically, no capacity planning
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "Terraform State Locks"
    Purpose   = "terraform-state-locking"
    ManagedBy = "Terraform"
  }

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }
}

# IAM policy for state bucket access (optional - for restricting access)
resource "aws_iam_policy" "terraform_state_access" {
  count       = var.create_access_policy ? 1 : 0
  name        = "TerraformStateAccess"
  description = "Policy for accessing Terraform state bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = aws_s3_bucket.terraform_state.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.terraform_locks.arn
      }
    ]
  })
}
