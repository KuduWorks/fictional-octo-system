output "org_budget_alerts_topic_arn" {
  description = "ARN of the organization budget alerts SNS topic"
  value       = aws_sns_topic.org_budget_alerts.arn
}

output "org_budget_alerts_topic_name" {
  description = "Name of the organization budget alerts SNS topic"
  value       = aws_sns_topic.org_budget_alerts.name
}

output "member_budget_alerts_topic_arn" {
  description = "ARN of the member account budget alerts SNS topic"
  value       = aws_sns_topic.member_budget_alerts.arn
}

output "member_budget_alerts_topic_name" {
  description = "Name of the member account budget alerts SNS topic"
  value       = aws_sns_topic.member_budget_alerts.name
}

output "org_alert_email" {
  description = "Email address configured for organization alerts"
  value       = var.org_alert_email
}

output "member_alert_email" {
  description = "Email address configured for member account alerts"
  value       = var.member_alert_email
}
