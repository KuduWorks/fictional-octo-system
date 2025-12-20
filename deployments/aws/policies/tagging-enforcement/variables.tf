variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "eu-north-1"
}

variable "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  type        = string
  default     = "tag-enforcement-config"
}

variable "create_config_recorder" {
  description = "Whether to create a new Config recorder (set to false if one already exists)"
  type        = bool
  default     = true
}

variable "config_bucket_prefix" {
  description = "Prefix for the S3 bucket storing Config data"
  type        = string
  default     = "aws-config-bucket"
}

variable "function_name_prefix" {
  description = "Prefix for Lambda function name"
  type        = string
  default     = "tag-enforcer"
}


variable "compliance_email" {
  description = "Email address for compliance team (receives all non-compliant resource reports)"
  type        = string
}

variable "ses_sender_email" {
  description = "Verified SES sender email address for sending compliance notifications"
  type        = string
}

variable "grace_period_days" {
  description = "Number of days before new resources are included in compliance checks"
  type        = number
  default     = 14
}

variable "resource_types_to_check" {
  description = "AWS resource types to check for tags (add more if you're feeling ambitious)"
  type        = list(string)
  default = [
    "AWS::EC2::Instance",
    "AWS::EC2::Volume",
    "AWS::EC2::SecurityGroup",
    "AWS::EC2::VPC",
    "AWS::EC2::Subnet",
    "AWS::S3::Bucket",
    "AWS::RDS::DBInstance",
    "AWS::Lambda::Function",
    "AWS::DynamoDB::Table",
    "AWS::ElasticLoadBalancingV2::LoadBalancer"
  ]
}


variable "dry_run_mode" {
  description = "Run in dry-run mode (logs emails without sending - recommended for testing)"
  type        = bool
  default     = true
}

variable "enable_sns_notifications" {
  description = "Enable SNS notifications for compliance changes"
  type        = bool
  default     = true
}

variable "notification_email" {
  description = "Email address to receive SNS notifications (optional)"
  type        = string
  default     = ""
}


variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms for non-compliance"
  type        = bool
  default     = true
}

variable "non_compliant_threshold" {
  description = "Number of non-compliant resources before alarm triggers (your tolerance for chaos)"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags to apply to all resources created by this module (meta-tagging!)"
  type        = map(string)
  default     = {}
}

variable "required_tags" {
  description = "List of required tag keys that must be present on all taggable resources"
  type        = list(string)
  default     = ["environment", "team", "costcenter"]
}

variable "auto_tag_enabled" {
  description = "Enable automatic tagging of non-compliant resources"
  type        = bool
  default     = false
}
