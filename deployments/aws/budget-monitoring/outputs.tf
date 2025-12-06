output "org_budget_name" {
  description = "Name of the organization budget"
  value       = aws_budgets_budget.organization.name
}

output "org_budget_id" {
  description = "ID of the organization budget"
  value       = aws_budgets_budget.organization.id
}

output "org_budget_limit" {
  description = "Organization budget limit in USD"
  value       = var.org_budget_limit
}

output "member_budget_name" {
  description = "Name of the member account budget"
  value       = var.member_account_id != "" ? aws_budgets_budget.member_account[0].name : null
}

output "member_budget_id" {
  description = "ID of the member account budget"
  value       = var.member_account_id != "" ? aws_budgets_budget.member_account[0].id : null
}

output "member_budget_limit" {
  description = "Member account budget limit in USD"
  value       = var.member_budget_limit
}

output "member_account_id" {
  description = "Member account ID being monitored"
  value       = var.member_account_id
}
