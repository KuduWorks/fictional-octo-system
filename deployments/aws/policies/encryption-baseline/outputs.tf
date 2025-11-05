output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = aws_config_configuration_recorder.main.id
}

output "config_bucket_name" {
  description = "Name of the S3 bucket for Config delivery"
  value       = aws_s3_bucket.config_bucket.id
}

output "config_rules" {
  description = "List of created AWS Config rules"
  value = [
    aws_config_config_rule.s3_bucket_encryption.name,
    aws_config_config_rule.s3_ssl_requests_only.name,
    aws_config_config_rule.ebs_encryption.name,
    aws_config_config_rule.rds_encryption.name,
    aws_config_config_rule.dynamodb_encryption.name,
    aws_config_config_rule.cloudtrail_encryption.name,
  ]
}

output "compliance_dashboard_url" {
  description = "URL to view compliance dashboard"
  value       = "https://console.aws.amazon.com/config/home?region=${var.aws_region}#/dashboard"
}
