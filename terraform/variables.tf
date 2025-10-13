variable "location" {
    description = "The Azure region to deploy resources in."
    type        = string
    default     = "Swedencentral"
}

variable "resource_group_name" {
    description = "The name of the resource group."
    type        = string
}

variable "tags" {
    description = "A mapping of tags to assign to resources."
    type        = map(string)
    default     = {}
}