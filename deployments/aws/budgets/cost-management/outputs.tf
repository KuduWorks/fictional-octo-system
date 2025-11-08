output "sns_topic_arn" {
  description = "ARN of the SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

output "sns_topic_name" {
  description = "Name of the SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.name
}

output "monthly_budget_id" {
  description = "ID of the monthly budget"
  value       = aws_budgets_budget.monthly_budget.id
}

output "monthly_budget_name" {
  description = "Name of the monthly budget"
  value       = aws_budgets_budget.monthly_budget.name
}

output "quarterly_budget_id" {
  description = "ID of the quarterly budget (if enabled)"
  value       = var.enable_quarterly_budget ? aws_budgets_budget.quarterly_budget[0].id : null
}

output "ec2_budget_id" {
  description = "ID of the EC2 service budget (if enabled)"
  value       = var.enable_service_budgets ? aws_budgets_budget.ec2_budget[0].id : null
}

output "s3_budget_id" {
  description = "ID of the S3 service budget (if enabled)"
  value       = var.enable_service_budgets ? aws_budgets_budget.s3_budget[0].id : null
}

output "tag_based_budget_ids" {
  description = "IDs of tag-based budgets"
  value       = { for k, v in aws_budgets_budget.tag_based_budget : k => v.id }
}

output "billing_dashboard_url" {
  description = "URL to AWS Billing Dashboard"
  value       = "https://console.aws.amazon.com/billing/home#/budgets"
}

output "cloudwatch_alarm_name" {
  description = "Name of CloudWatch billing alarm (if enabled)"
  value       = var.enable_cloudwatch_billing_alarm ? aws_cloudwatch_metric_alarm.billing_alarm[0].alarm_name : null
}

output "account_id" {
  description = "AWS Account ID where budgets are created"
  value       = local.account_id
}

output "alert_email_addresses" {
  description = "Email addresses configured for budget alerts"
  value       = var.alert_email_addresses
  sensitive   = true
}
