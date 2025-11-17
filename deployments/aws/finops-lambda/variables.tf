variable "alert_email" {
  description = "Email address to send cost anomaly alerts to. Must be SES-verified."
  type        = string
}

variable "anomaly_threshold" {
  description = "Threshold multiplier for anomaly detection (e.g., 1.2 for 20% increase)."
  type        = string
  default     = "1.2"
}
