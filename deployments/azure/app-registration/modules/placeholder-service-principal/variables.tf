variable "placeholder_name" {
  description = "Display name for the placeholder service principal. Should clearly indicate this is a temporary placeholder."
  type        = string
  default     = "PLACEHOLDER-AppRegistration-Owner"
  
  validation {
    condition     = can(regex("(?i)placeholder", var.placeholder_name))
    error_message = "Placeholder name must contain 'placeholder' (case-insensitive) to clearly identify it as temporary."
  }
  
  validation {
    condition     = length(var.placeholder_name) >= 10 && length(var.placeholder_name) <= 120
    error_message = "Placeholder name must be between 10 and 120 characters."
  }
}

variable "justification" {
  description = <<-EOT
    Detailed justification (minimum 50 characters) explaining why a placeholder service principal is needed.
    This should document:
    - Why 2 human owners are not available
    - Timeline for replacing placeholder with human owner
    - Business context requiring application creation before owners are identified
    
    This justification will be audited quarterly (Q2/Q4 first Monday).
    Placeholders existing >6 months will be escalated to leadership.
  EOT
  type        = string
  sensitive   = false  # Justifications are audit trail, not sensitive
  
  validation {
    condition     = length(var.justification) >= 50
    error_message = "Justification must be at least 50 characters. Current length: ${length(var.justification)}. Provide detailed business context for quarterly audit trail."
  }
  
  validation {
    condition     = length(var.justification) <= 2000
    error_message = "Justification must be at most 2000 characters to fit in Azure AD notes field."
  }
  
  validation {
    condition     = can(regex("^[^<>\"'&]*$", var.justification))
    error_message = "Justification must not contain HTML/script special characters (<, >, \", ', &) to prevent injection attacks in notifications/reports."
  }
  
  validation {
    condition     = !can(regex("(?i)(test|temp|temporary|todo|tbd|n/a|none)", var.justification))
    error_message = "Justification appears to be placeholder text (test/temp/todo/tbd/n/a/none). Provide substantive business justification for audit compliance."
  }
}

variable "created_by_workflow" {
  description = "GitHub Actions workflow or user that created this placeholder. Used for accountability in quarterly reviews."
  type        = string
  default     = "manual"
}

variable "tags" {
  description = "Additional tags to apply to the application and service principal. Core placeholder tags are applied automatically."
  type        = list(string)
  default     = []
}
