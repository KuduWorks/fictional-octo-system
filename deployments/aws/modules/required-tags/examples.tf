# Example usage patterns for the required-tags module
# Copy these patterns into your actual Terraform configurations

# Example 1: Basic resource with merge()
# -----------------------------------------------------------------------------
module "tags" {
  source = "../../modules/required-tags"

  environment = "production"
  team        = "platform-engineering"
  costcenter  = "eng-0001"
}

resource "aws_s3_bucket" "example" {
  bucket = "my-application-bucket"

  tags = merge(
    module.tags.baseline_tags,
    {
      application         = "customer-portal"
      data_classification = "confidential"
      backup_required     = "true"
    }
  )
}

# Example 2: Provider default_tags (RECOMMENDED)
# -----------------------------------------------------------------------------
# This automatically applies governance tags to ALL resources
provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = module.tags.baseline_tags
  }
}

# Now resources only need custom tags
resource "aws_ec2_instance" "app_server" {
  ami           = "ami-12345678"
  instance_type = "t3.micro"

  # Governance tags automatically applied by provider
  # Only add resource-specific tags
  tags = {
    name        = "app-server-01"
    application = "web-api"
  }
}

# Example 3: Multiple environments
# -----------------------------------------------------------------------------
locals {
  environments = {
    dev = {
      environment = "dev"
      team        = "platform-engineering"
      costcenter  = "eng-0001"
    }
    prod = {
      environment = "production"
      team        = "platform-engineering"
      costcenter  = "eng-0001"
    }
  }
}

module "tags_dev" {
  source = "../../modules/required-tags"

  environment = local.environments.dev.environment
  team        = local.environments.dev.team
  costcenter  = local.environments.dev.costcenter
}

module "tags_prod" {
  source = "../../modules/required-tags"

  environment = local.environments.prod.environment
  team        = local.environments.prod.team
  costcenter  = local.environments.prod.costcenter
}

# Example 4: Preventing tag drift with lifecycle
# -----------------------------------------------------------------------------
# If you want to ignore external tag changes (not recommended for governance tags)
resource "aws_rds_instance" "database" {
  identifier     = "app-database"
  engine         = "postgres"
  instance_class = "db.t3.micro"

  tags = merge(
    module.tags.baseline_tags,
    {
      database_name = "application_db"
      backup_window = "03:00-04:00"
    }
  )

  # Only use this if you have external tagging systems
  # For governance tags, prefer using merge() instead
  lifecycle {
    ignore_changes = [
      # Don't ignore governance tags - let Terraform manage them
      # tags["environment"],
      # tags["team"],
      # tags["costcenter"],
      
      # You can ignore other external tags
      # tags["auto_tagged_by_automation"],
    ]
  }
}

# Example 5: Conditional tagging
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "processor" {
  function_name = "data-processor"
  runtime       = "python3.11"
  handler       = "index.handler"
  role          = aws_iam_role.lambda.arn

  tags = merge(
    module.tags.baseline_tags,
    {
      function_type = "data-processing"
    },
    # Conditionally add production-specific tags
    var.environment == "production" ? {
      high_availability = "true"
      monitoring_level  = "detailed"
    } : {}
  )
}

# Example 6: Dynamic resource tagging
# -----------------------------------------------------------------------------
variable "applications" {
  type = map(object({
    custom_tags = map(string)
  }))
  default = {
    "web-app" = {
      custom_tags = {
        application = "web-frontend"
        tier        = "presentation"
      }
    }
    "api" = {
      custom_tags = {
        application = "rest-api"
        tier        = "application"
      }
    }
  }
}

resource "aws_s3_bucket" "app_buckets" {
  for_each = var.applications

  bucket = "${each.key}-bucket"

  tags = merge(
    module.tags.baseline_tags,
    each.value.custom_tags
  )
}
