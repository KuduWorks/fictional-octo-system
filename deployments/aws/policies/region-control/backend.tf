# Backend configuration for Terraform state
# Uncomment and configure after creating the backend resources

# terraform {
#   backend "s3" {
#     bucket         = "fictional-octo-system-tfstate-ACCOUNT_ID"
#     key            = "policies/region-control/terraform.tfstate"
#     region         = "eu-north-1"
#     dynamodb_table = "terraform-state-locks"
#     encrypt        = true
#   }
# }
