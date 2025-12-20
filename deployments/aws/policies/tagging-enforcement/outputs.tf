output "config_recorder_id" {
  description = "ID of the AWS Config recorder"
  value       = var.create_config_recorder ? aws_config_configuration_recorder.main[0].id : "Using existing recorder"
}

output "config_bucket_name" {
  description = "Name of the S3 bucket storing Config data"
  value       = var.create_config_recorder ? aws_s3_bucket.config[0].id : "Using existing bucket"
}

output "config_rule_arn" {
  description = "ARN of the required tags Config rule (the enforcer)"
  value       = aws_config_config_rule.required_tags.arn
}

output "lambda_function_arn" {
  description = "ARN of the tag remediation Lambda function (the fixer)"
  value       = aws_lambda_function.tag_remediation.arn
}

output "lambda_function_name" {
  description = "Name of the tag remediation Lambda function"
  value       = aws_lambda_function.tag_remediation.function_name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic for notifications (where the alerts go)"
  value       = aws_sns_topic.notifications.arn
}

output "eventbridge_rule_name" {
  description = "Name of the EventBridge rule monitoring compliance"
  value       = aws_cloudwatch_event_rule.daily_compliance_check.name
}

output "required_tags" {
  description = "List of required tags being enforced"
  value       = var.required_tags
}

output "monitored_resource_types" {
  description = "Resource types being monitored for compliance"
  value       = var.resource_types_to_check
}

output "auto_tagging_status" {
  description = "Whether automatic tagging is enabled (robot overlords active: yes/no)"
  value       = var.auto_tag_enabled ? "ENABLED - Auto-tagging active 🤖" : "DISABLED - Alert only mode 📢"
}

output "dry_run_status" {
  description = "Whether dry-run mode is active (practice mode)"
  value       = var.dry_run_mode ? "ACTIVE - No actual changes will be made" : "INACTIVE - Real changes will occur"
}

output "cloudwatch_alarm_names" {
  description = "Names of CloudWatch alarms created"
  value = var.enable_cloudwatch_alarms ? {
    non_compliant = aws_cloudwatch_metric_alarm.non_compliant_resources[0].alarm_name
    lambda_errors = aws_cloudwatch_metric_alarm.lambda_errors[0].alarm_name
  } : {}
}
