variable "location" {
  description = "The Azure region to deploy resources in."
  type        = string
  default     = "swedencentral"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-monitoring" # Add default value
}

variable "tags" {
  description = "A mapping of tags to assign to resources."
  type        = map(string)
  default = {
    environment = "dev"
    project     = "fictional-octo-system"
    deployed_by = "terraform"
  }
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_prefix" {
  description = "The address prefix for the subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "alert_email" {
  description = "Email address for receiving alerts"
  type        = string
  default     = "monitoring@kuduworks.net" # Add default value
}

variable "allowed_ip_addresses" {
  description = "List of IP addresses allowed to access the storage account"
  type        = list(string)
  default     = ["85.131.104.114"]
}