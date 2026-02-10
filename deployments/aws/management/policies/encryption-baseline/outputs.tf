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

# RDS Parameter Groups for SSL Enforcement
output "rds_parameter_groups" {
  description = "RDS parameter groups that enforce SSL/TLS connections (all versions)"
  value = {
    postgresql = {
      for family in local.postgresql_families :
      family => {
        name   = aws_db_parameter_group.postgresql_ssl_required[family].name
        arn    = aws_db_parameter_group.postgresql_ssl_required[family].arn
        family = aws_db_parameter_group.postgresql_ssl_required[family].family
      }
    }
    mysql = {
      for family in local.mysql_families :
      family => {
        name   = aws_db_parameter_group.mysql_ssl_required[family].name
        arn    = aws_db_parameter_group.mysql_ssl_required[family].arn
        family = aws_db_parameter_group.mysql_ssl_required[family].family
      }
    }
    aurora_postgresql = {
      for family in local.aurora_pg_families :
      family => {
        name   = aws_rds_cluster_parameter_group.aurora_postgresql_ssl_required[family].name
        arn    = aws_rds_cluster_parameter_group.aurora_postgresql_ssl_required[family].arn
        family = aws_rds_cluster_parameter_group.aurora_postgresql_ssl_required[family].family
      }
    }
    aurora_mysql = {
      for family in local.aurora_my_families :
      family => {
        name   = aws_rds_cluster_parameter_group.aurora_mysql_ssl_required[family].name
        arn    = aws_rds_cluster_parameter_group.aurora_mysql_ssl_required[family].arn
        family = aws_rds_cluster_parameter_group.aurora_mysql_ssl_required[family].family
      }
    }
  }
}

output "rds_ssl_enforcement_instructions" {
  description = "Instructions for using SSL-enforcing parameter groups"
  value = <<-EOT
    To enforce SSL/TLS for RDS instances:
    
    Available PostgreSQL parameter groups (by version):
    ${join("\n    ", [for f in local.postgresql_families : "- ${aws_db_parameter_group.postgresql_ssl_required[f].name}"])}
    
    Available MySQL parameter groups (by version):
    ${join("\n    ", [for f in local.mysql_families : "- ${aws_db_parameter_group.mysql_ssl_required[f].name}"])}
    
    Available Aurora PostgreSQL parameter groups (by version):
    ${join("\n    ", [for f in local.aurora_pg_families : "- ${aws_rds_cluster_parameter_group.aurora_postgresql_ssl_required[f].name}"])}
    
    Available Aurora MySQL parameter groups (by version):
    ${join("\n    ", [for f in local.aurora_my_families : "- ${aws_rds_cluster_parameter_group.aurora_mysql_ssl_required[f].name}"])}
    
    Select the parameter group that matches your RDS instance version.
  EOT
}
