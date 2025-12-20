terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

# Data source to get current account and region
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Data source for the Lambda zip
data "archive_file" "lambda" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

###############################################################################
# AWS Config Setup
###############################################################################

# Config Recorder (if not already exists)
resource "aws_config_configuration_recorder" "main" {
  count = var.create_config_recorder ? 1 : 0

  name     = var.config_recorder_name
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count = var.create_config_recorder ? 1 : 0

  name           = var.config_recorder_name
  s3_bucket_name = aws_s3_bucket.config[0].id
  sns_topic_arn  = var.enable_sns_notifications ? aws_sns_topic.config[0].arn : null

  depends_on = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  count = var.create_config_recorder ? 1 : 0

  name       = aws_config_configuration_recorder.main[0].name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# S3 bucket for Config
resource "aws_s3_bucket" "config" {
  count = var.create_config_recorder ? 1 : 0

  bucket = "${var.config_bucket_prefix}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "AWS Config Bucket"
      Description = "Where Config dumps its homework"
    }
  )
}

resource "aws_s3_bucket_versioning" "config" {
  count = var.create_config_recorder ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config" {
  count = var.create_config_recorder ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "config" {
  count = var.create_config_recorder ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "config" {
  count = var.create_config_recorder ? 1 : 0

  bucket = aws_s3_bucket.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config[0].arn
      },
      {
        Sid    = "AWSConfigBucketPutObject"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config[0].arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# SNS Topic for Config notifications
resource "aws_sns_topic" "config" {
  count = var.enable_sns_notifications && var.create_config_recorder ? 1 : 0

  name = "${var.config_recorder_name}-notifications"

  tags = merge(
    var.tags,
    {
      Name        = "Config Notifications"
      Description = "Where Config shouts about non-compliance"
    }
  )
}

# IAM Role for Config
resource "aws_iam_role" "config" {
  count = var.create_config_recorder ? 1 : 0

  name = "${var.config_recorder_name}-role"

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

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count = var.create_config_recorder ? 1 : 0

  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

resource "aws_iam_role_policy" "config_s3" {
  count = var.create_config_recorder ? 1 : 0

  name = "config-s3-policy"
  role = aws_iam_role.config[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.config[0].arn,
          "${aws_s3_bucket.config[0].arn}/*"
        ]
      }
    ]
  })
}

###############################################################################
# AWS Config Rules for Tag Enforcement
###############################################################################

# Rule: Check if required tags exist on taggable resources only
resource "aws_config_config_rule" "required_tags" {
  name        = "required-tags-check"
  description = "Checks if taggable resources have all required tags (environment, team, costcenter)"

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    for idx, tag_key in var.required_tags :
    "tag${idx + 1}Key" => tag_key
    if idx < 3
  })

  scope {
    # Only check resource types that support tagging
    # AWS Config will filter out non-taggable resources automatically
    compliance_resource_types = var.resource_types_to_check
  }

  depends_on = var.create_config_recorder ? [aws_config_configuration_recorder.main] : []

  tags = var.tags
}

# Note: Removed real-time compliance trigger
# Tag validation now runs daily at 2am UTC via EventBridge scheduled rule
# This prevents alert fatigue and gives teams time to remediate

###############################################################################
# S3 Bucket for Team Email YAML Configuration
###############################################################################

resource "aws_s3_bucket" "team_config" {
  bucket = "${var.function_name_prefix}-team-config-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.tags,
    {
      Name        = "Tag Enforcement Team Configuration"
      Description = "Stores approved-tags.yaml for compliance validation"
    }
  )
}

resource "aws_s3_bucket_versioning" "team_config" {
  bucket = aws_s3_bucket.team_config.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "team_config" {
  bucket = aws_s3_bucket.team_config.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "team_config" {
  bucket = aws_s3_bucket.team_config.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Upload approved-tags.yaml to S3
resource "aws_s3_object" "team_emails" {
  bucket       = aws_s3_bucket.team_config.id
  key          = "approved-tags.yaml"
  source       = "${path.module}/approved-tags.yaml"
  etag         = filemd5("${path.module}/approved-tags.yaml")
  content_type = "application/x-yaml"

  tags = var.tags
}

###############################################################################
# EventBridge Rule for Daily Compliance Check
###############################################################################

# Daily scheduled trigger at 2am UTC
resource "aws_cloudwatch_event_rule" "daily_compliance_check" {
  name                = "daily-tag-compliance-check"
  description         = "Triggers daily at 2am UTC to check tag compliance and send digest emails"
  schedule_expression = "cron(0 2 * * ? *)"

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.daily_compliance_check.name
  target_id = "TagComplianceLambda"
  arn       = aws_lambda_function.tag_remediation.arn
}

###############################################################################
# Lambda Function for Auto-Remediation
###############################################################################

resource "aws_lambda_function" "tag_remediation" {
  filename      = data.archive_file.lambda.output_path
  function_name = "${var.function_name_prefix}-tag-remediation"
  role          = aws_iam_role.lambda.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 300

  source_code_hash = data.archive_file.lambda.output_base64sha256

  environment {
    variables = {
      REQUIRED_TAGS      = jsonencode(var.required_tags)
      COMPLIANCE_EMAIL   = var.compliance_email
      TEAM_CONFIG_BUCKET = aws_s3_bucket.team_config.id
      TEAM_CONFIG_KEY    = aws_s3_object.team_emails.key
      GRACE_PERIOD_DAYS  = var.grace_period_days
      DRY_RUN            = var.dry_run_mode
      CONFIG_PAGE_SIZE   = var.config_page_size
    }
  }

  tags = merge(
    var.tags,
    {
      Name        = "Tag Enforcement Lambda"
      Description = "The tag police 👮"
    }
  )
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tag_remediation.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_compliance_check.arn
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda" {
  name = "${var.function_name_prefix}-tag-remediation-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_tagging" {
  name = "lambda-tagging-policy"
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "config:GetComplianceDetailsByConfigRule",
          "config:DescribeConfigRules",
          "config:ListDiscoveredResources",
          "config:GetResourceConfigHistory"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.team_config.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = aws_s3_bucket.team_config.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.notifications.arn
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeTags",
          "s3:GetBucketTagging",
          "rds:ListTagsForResource",
          "lambda:ListTags",
          "dynamodb:ListTagsOfResource",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################################
# SNS Topic for Remediation Notifications
###############################################################################

resource "aws_sns_topic" "notifications" {
  name = "${var.function_name_prefix}-tag-remediation-notifications"

  tags = merge(
    var.tags,
    {
      Name        = "Tag Remediation Notifications"
      Description = "Get notified when resources get auto-tagged (or shamed)"
    }
  )
}

resource "aws_sns_topic_subscription" "email" {
  count = var.notification_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.notifications.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

###############################################################################
# CloudWatch Alarms (Optional)
###############################################################################

resource "aws_cloudwatch_metric_alarm" "non_compliant_resources" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name_prefix}-non-compliant-resources"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NonCompliantResources"
  namespace           = "AWS/Config"
  period              = "300"
  statistic           = "Maximum"
  threshold           = var.non_compliant_threshold
  alarm_description   = "Alert when too many resources are missing tags (dev team slacking)"
  alarm_actions       = var.enable_sns_notifications ? [aws_sns_topic.notifications.arn] : []

  dimensions = {
    RuleName = aws_config_config_rule.required_tags.name
  }

  tags = var.tags
}

# Lambda error alarm
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  count = var.enable_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${var.function_name_prefix}-tag-remediation-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "Alert when tag remediation Lambda fails (robots need debugging too)"
  alarm_actions       = var.enable_sns_notifications ? [aws_sns_topic.notifications.arn] : []

  dimensions = {
    FunctionName = aws_lambda_function.tag_remediation.function_name
  }

  tags = var.tags
}
