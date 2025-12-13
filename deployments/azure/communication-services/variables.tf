variable "resource_group_name" {
  description = "Name of the resource group for Communication Services"
  type        = string
  default     = "rg-communication-services"
}

variable "location" {
  description = "Azure region for Communication Services"
  type        = string
  default     = "eastus"
}

variable "communication_service_name" {
  description = "Name of the Communication Service"
  type        = string
  default     = "acs-app-registration-notifications"
}

variable "data_location" {
  description = "Data residency location for Communication Services (United States, Europe, etc.)"
  type        = string
  default     = "United States"
}

variable "domain_name" {
  description = "Custom domain name for email (e.g., notifications.yourcompany.com)"
  type        = string
}

variable "sender_username" {
  description = "Sender username for emails (creates username@domain)"
  type        = string
  default     = "no-reply"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "Production"
    Purpose     = "App Registration Notifications"
  }
}
