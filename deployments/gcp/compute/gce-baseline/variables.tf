variable "gcp_region" {
  description = "GCP region for resources"
  type        = string
  default     = "europe-north1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name of the compute instance"
  type        = string
  default     = "baseline-instance"
}

variable "machine_type" {
  description = "Machine type for compute instance"
  type        = string
  default     = "e2-micro"
  
  validation {
    condition = contains([
      "e2-micro", "e2-small", "e2-medium", 
      "f1-micro", "g1-small"
    ], var.machine_type)
    error_message = "Machine type must be a valid GCE instance type."
  }
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB"
  type        = number
  default     = 30
}

variable "enable_os_login" {
  description = "Enable OS Login for secure SSH access"
  type        = bool
  default     = true
}

variable "enable_shielded_vm" {
  description = "Enable Shielded VM for additional security"
  type        = bool
  default     = true
}