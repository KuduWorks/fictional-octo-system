output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.id
}

output "cloudtrail_bucket_arn" {
  description = "ARN of the S3 bucket storing CloudTrail logs"
  value       = aws_s3_bucket.cloudtrail.arn
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail organization trail"
  value       = aws_cloudtrail.organization.arn
}

output "cloudtrail_trail_id" {
  description = "Name of the CloudTrail organization trail"
  value       = aws_cloudtrail.organization.id
}

output "organization_id" {
  description = "AWS Organization ID"
  value       = data.aws_organizations_organization.current.id
}

output "log_retention_days" {
  description = "Number of days CloudTrail logs are retained"
  value       = var.log_retention_days
}
