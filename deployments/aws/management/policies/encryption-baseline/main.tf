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
      Module      = "encryption-baseline"
      Purpose     = "ISO27001-Compliance"
    }
  }
}

# Data source to get current AWS account
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
}

# AWS Config Rule: S3 Bucket Encryption
resource "aws_config_config_rule" "s3_bucket_encryption" {
  name        = "s3-bucket-server-side-encryption-enabled"
  description = "Checks that S3 buckets have encryption enabled (ISO 27001 A.10.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: S3 HTTPS Only
resource "aws_config_config_rule" "s3_ssl_requests_only" {
  name        = "s3-bucket-ssl-requests-only"
  description = "Checks that S3 buckets require HTTPS (ISO 27001 A.10.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_SSL_REQUESTS_ONLY"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: EBS Volume Encryption
resource "aws_config_config_rule" "ebs_encryption" {
  name        = "encrypted-volumes"
  description = "Checks that EBS volumes are encrypted (ISO 27001 A.10.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "ENCRYPTED_VOLUMES"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: RDS Encryption
resource "aws_config_config_rule" "rds_encryption" {
  name        = "rds-storage-encrypted"
  description = "Checks that RDS instances use encryption (ISO 27001 A.10.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: DynamoDB Encryption
resource "aws_config_config_rule" "dynamodb_encryption" {
  name        = "dynamodb-table-encrypted-kms"
  description = "Checks that DynamoDB tables use KMS encryption (ISO 27001 A.10.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "DYNAMODB_TABLE_ENCRYPTED_KMS"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: CloudTrail Encryption
resource "aws_config_config_rule" "cloudtrail_encryption" {
  name        = "cloudtrail-encryption-enabled"
  description = "Checks that CloudTrail logs are encrypted (ISO 27001 A.12.4.1)"

  source {
    owner             = "AWS"
    source_identifier = "CLOUD_TRAIL_ENCRYPTION_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# IAM Role for AWS Config
resource "aws_iam_role" "config_role" {
  name = "aws-config-encryption-baseline-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for Config
resource "aws_iam_role_policy_attachment" "config_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
  role       = aws_iam_role.config_role.name
}

# S3 bucket for Config delivery
resource "aws_s3_bucket" "config_bucket" {
  bucket = "aws-config-encryption-baseline-${local.account_id}"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket_public_access" {
  bucket = aws_s3_bucket.config_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket policy for Config
resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketPutObject"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "encryption-baseline-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported = false
    resource_types = [
      "AWS::S3::Bucket",
      "AWS::S3::AccountPublicAccessBlock",
      "AWS::EC2::Volume",
      "AWS::RDS::DBInstance",
      "AWS::RDS::DBCluster",
      "AWS::DynamoDB::Table",
      "AWS::CloudTrail::Trail"
    ]
  }
}

# AWS Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "${var.config_recorder_name}-delivery"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket

  depends_on = [aws_config_configuration_recorder.main]
}

# Start the Config Recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# ============================================================================
# S3 PUBLIC ACCESS CONFIG RULES
# ============================================================================

# AWS Config Rule: S3 Public Read Prohibited
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name        = "s3-bucket-public-read-prohibited"
  description = "Checks that S3 buckets do not allow public read access (ISO 27001 A.9.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: S3 Public Write Prohibited
resource "aws_config_config_rule" "s3_bucket_public_write_prohibited" {
  name        = "s3-bucket-public-write-prohibited"
  description = "Checks that S3 buckets do not allow public write access (ISO 27001 A.9.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder.main]
}

# AWS Config Rule: S3 Account Level Public Access Blocks
resource "aws_config_config_rule" "s3_account_level_public_access_blocks" {
  name        = "s3-account-level-public-access-blocks-periodic"
  description = "Checks whether the required public access block settings are configured at the account level (ISO 27001 A.9.1.1)"

  source {
    owner             = "AWS"
    source_identifier = "S3_ACCOUNT_LEVEL_PUBLIC_ACCESS_BLOCKS_PERIODIC"
  }

  input_parameters = jsonencode({
    BlockPublicAcls       = "true"
    BlockPublicPolicy     = "true"
    IgnorePublicAcls      = "true"
    RestrictPublicBuckets = "true"
  })

  depends_on = [aws_config_configuration_recorder.main]
}

# ============================================================================
# ACCOUNT-LEVEL S3 PUBLIC ACCESS BLOCK
# ============================================================================

# Block public access at the account level
resource "aws_s3_account_public_access_block" "account_level_block" {
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ============================================================================
# SERVICE CONTROL POLICIES (PREVENTIVE CONTROLS)
# ============================================================================

# Data source to get organization information
data "aws_organizations_organization" "current" {
  count = var.enable_scps ? 1 : 0
}

# SCP: Deny S3 Public Access Actions
resource "aws_organizations_policy" "deny_s3_public_access" {
  count = var.enable_scps ? 1 : 0

  name        = "DenyS3PublicAccess"
  description = "Prevents S3 buckets from being made public - ISO 27001 A.9.1.1 compliance"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRemovingPublicAccessBlock"
        Effect = "Deny"
        Action = [
          "s3:DeleteBucketPublicAccessBlock",
          "s3:DeleteAccountPublicAccessBlock"
        ]
        Resource = "*"
      },
      {
        Sid    = "DenyWeakeningPublicAccessBlock"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPublicAccessBlock",
          "s3:PutAccountPublicAccessBlock"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "s3:PublicAccessBlockConfiguration.BlockPublicAcls"       = "false"
            "s3:PublicAccessBlockConfiguration.BlockPublicPolicy"     = "false"
            "s3:PublicAccessBlockConfiguration.IgnorePublicAcls"      = "false"
            "s3:PublicAccessBlockConfiguration.RestrictPublicBuckets" = "false"
          }
        }
      },
      {
        Sid    = "DenyS3PublicACLs"
        Effect = "Deny"
        Action = [
          "s3:PutBucketAcl",
          "s3:PutObjectAcl"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "s3:x-amz-acl" = [
              "public-read",
              "public-read-write",
              "authenticated-read"
            ]
          }
        }
      },
      {
        Sid    = "DenyS3PublicBucketPolicy"
        Effect = "Deny"
        Action = [
          "s3:PutBucketPolicy"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "s3:x-amz-grant-read" = "*"
          }
        }
      }
    ]
  })
}

# Attach SCP to organization root
resource "aws_organizations_policy_attachment" "deny_s3_public_access_attachment" {
  count = var.enable_scps ? 1 : 0

  policy_id = aws_organizations_policy.deny_s3_public_access[0].id
  target_id = data.aws_organizations_organization.current[0].roots[0].id
}

# ============================================================================
# RDS ENCRYPTION IN TRANSIT (SSL/TLS)
# ============================================================================

# Note: AWS Config does not have a managed rule for RDS SSL enforcement.
# To enforce SSL/TLS for RDS connections:
# 1. Create RDS parameter groups with rds.force_ssl=1 (PostgreSQL/Aurora PostgreSQL)
# 2. Or require_secure_transport=ON (MySQL/Aurora MySQL)
# 3. Attach these parameter groups to all RDS instances
# 4. Use the parameter groups defined below

# PostgreSQL Parameter Groups (Multiple Versions)
locals {
  postgresql_families = ["postgres12", "postgres13", "postgres14", "postgres15", "postgres16"]
  mysql_families      = ["mysql5.7", "mysql8.0"]
  aurora_pg_families  = ["aurora-postgresql13", "aurora-postgresql14", "aurora-postgresql15", "aurora-postgresql16"]
  aurora_my_families  = ["aurora-mysql5.7", "aurora-mysql8.0"]
}

# RDS Parameter Group: PostgreSQL with SSL enforcement (all supported versions)
resource "aws_db_parameter_group" "postgresql_ssl_required" {
  for_each = toset(local.postgresql_families)

  name        = "postgresql-${each.value}-ssl-required"
  family      = each.value
  description = "PostgreSQL ${each.value} parameter group requiring SSL connections (ISO 27001 A.10.1.1)"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name    = "postgresql-${each.value}-ssl-required"
    Purpose = "Force-SSL-Connections"
    Version = each.value
  }
}

# RDS Parameter Group: MySQL with SSL enforcement (all supported versions)
resource "aws_db_parameter_group" "mysql_ssl_required" {
  for_each = toset(local.mysql_families)

  name        = "mysql-${replace(each.value, ".", "")}-ssl-required"
  family      = each.value
  description = "MySQL ${each.value} parameter group requiring SSL connections (ISO 27001 A.10.1.1)"

  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }

  tags = {
    Name    = "mysql-${each.value}-ssl-required"
    Purpose = "Force-SSL-Connections"
    Version = each.value
  }
}

# RDS Cluster Parameter Group: Aurora PostgreSQL with SSL enforcement (all supported versions)
resource "aws_rds_cluster_parameter_group" "aurora_postgresql_ssl_required" {
  for_each = toset(local.aurora_pg_families)

  name        = "${each.value}-ssl-required"
  family      = each.value
  description = "Aurora PostgreSQL ${each.value} parameter group requiring SSL connections (ISO 27001 A.10.1.1)"

  parameter {
    name  = "rds.force_ssl"
    value = "1"
  }

  tags = {
    Name    = "${each.value}-ssl-required"
    Purpose = "Force-SSL-Connections"
    Version = each.value
  }
}

# RDS Cluster Parameter Group: Aurora MySQL with SSL enforcement (all supported versions)
resource "aws_rds_cluster_parameter_group" "aurora_mysql_ssl_required" {
  for_each = toset(local.aurora_my_families)

  name        = replace("${each.value}-ssl-required", ".", "-")  # Replace dots with hyphens for valid name
  family      = each.value
  description = "Aurora MySQL ${each.value} parameter group requiring SSL connections (ISO 27001 A.10.1.1)"

  parameter {
    name  = "require_secure_transport"
    value = "ON"
  }

  tags = {
    Name    = "${each.value}-ssl-required"
    Purpose = "Force-SSL-Connections"
    Version = each.value
  }
}


# ============================================================================
# EVENTBRIDGE: CONFIG COMPLIANCE ALERTS
# ============================================================================

# EventBridge Rule: Capture Config compliance changes
resource "aws_cloudwatch_event_rule" "config_compliance_change" {
  count = var.security_sns_topic_arn != "" ? 1 : 0

  name        = "config-compliance-violations"
  description = "Capture AWS Config compliance changes to NON_COMPLIANT status"

  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Rules Compliance Change"]
    detail = {
      newEvaluationResult = {
        complianceType = ["NON_COMPLIANT"]
      }
    }
  })

  tags = {
    Name    = "config-compliance-violations"
    Purpose = "Security-Alerting"
  }
}

# EventBridge Target: Route to SNS
resource "aws_cloudwatch_event_target" "config_to_sns" {
  count = var.security_sns_topic_arn != "" ? 1 : 0

  rule      = aws_cloudwatch_event_rule.config_compliance_change[0].name
  target_id = "SendToSecuritySNS"
  arn       = var.security_sns_topic_arn

  input_transformer {
    input_paths = {
      rule         = "$.detail.configRuleName"
      resource     = "$.detail.resourceId"
      resourceType = "$.detail.resourceType"
      compliance   = "$.detail.newEvaluationResult.complianceType"
      region       = "$.detail.awsRegion"
      account      = "$.detail.awsAccountId"
    }
    input_template = <<EOF
🚨 AWS Config Compliance Violation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Rule:          <rule>
Status:        <compliance>
Resource:      <resource>
Type:          <resourceType>
Region:        <region>
Account:       <account>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Action Required: Review and remediate the non-compliant resource.
EOF
  }
}

# IAM Policy: Allow EventBridge to publish to SNS
resource "aws_sns_topic_policy" "security_alerts_eventbridge" {
  count = var.security_sns_topic_arn != "" ? 1 : 0

  arn = var.security_sns_topic_arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEventBridgePublish"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = var.security_sns_topic_arn
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = local.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:events:${var.aws_region}:${local.account_id}:rule/*"
          }
        }
      }
    ]
  })
}
