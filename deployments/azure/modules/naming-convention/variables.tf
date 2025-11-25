variable "workload" {
  description = "The name of the workload or application (e.g., 'finops', 'webapp', 'api')"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.workload))
    error_message = "Workload must be 2-10 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "The environment (e.g., 'dev', 'test', 'prod')"
  type        = string
  
  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, stage, prod."
  }
}

variable "region" {
  description = "The Azure region (e.g., 'eastus', 'westeurope')"
  type        = string
}

variable "instance" {
  description = "Instance number for resource (e.g., '01', '02', '001')"
  type        = string
  default     = "01"
  
  validation {
    condition     = can(regex("^[0-9]{1,3}$", var.instance))
    error_message = "Instance must be 1-3 digits."
  }
}

variable "subnet_purpose" {
  description = "Purpose of the subnet (e.g., 'web', 'db', 'app')"
  type        = string
  default     = "default"
}

variable "additional_tags" {
  description = "Additional tags to merge with common tags"
  type        = map(string)
  default     = {}
}
