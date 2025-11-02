variable "require_encryption" {
  default = true  # Resources MUST have encryption (CMK OR PMK)
}

variable "audit_encryption_type" {
  default = true  # Report on CMK vs PMK usage
}