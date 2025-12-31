# ==============================================================================
# Cloud Run API Monitoring - Variables
# ==============================================================================
# Monitors latency and error rate for Cloud Run services.
#
# Alerts are tiered by severity:
# - CRITICAL: Requires immediate attention (pages on-call)
# - WARNING: Informational, review during business hours
# ==============================================================================

# ------------------------------------------------------------------------------
# Required Variables
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "The Google Cloud project ID where the Cloud Run service is deployed."
  type        = string
}

variable "service_name" {
  description = "The exact name of the Cloud Run service to monitor."
  type        = string
}

variable "region" {
  description = "The region where the Cloud Run service is deployed (e.g., 'us-central1')."
  type        = string
}

# ------------------------------------------------------------------------------
# Notification Channels (by severity)
# ------------------------------------------------------------------------------

variable "critical_notification_channels" {
  description = "Notification channels for CRITICAL alerts (e.g., PagerDuty)."
  type        = list(string)
  default     = []
}

variable "warning_notification_channels" {
  description = "Notification channels for WARNING alerts (e.g., Slack)."
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# Alert Enable/Disable Toggles
# ------------------------------------------------------------------------------

variable "enable_latency_alerts" {
  description = "Enable latency monitoring alerts."
  type        = bool
  default     = true
}

variable "enable_error_alerts" {
  description = "Enable 5xx error rate monitoring alerts."
  type        = bool
  default     = true
}

# ------------------------------------------------------------------------------
# Latency Thresholds
# ------------------------------------------------------------------------------

variable "latency_warning_ms" {
  description = "P95 latency threshold in milliseconds for WARNING alerts."
  type        = number
  default     = 2000
}

variable "latency_critical_ms" {
  description = "P95 latency threshold in milliseconds for CRITICAL alerts."
  type        = number
  default     = 5000
}

# ------------------------------------------------------------------------------
# Error Rate Thresholds
# ------------------------------------------------------------------------------

variable "error_rate_warning" {
  description = "5xx error rate threshold for WARNING alerts (0.01 = 1%)."
  type        = number
  default     = 0.01

  validation {
    condition     = var.error_rate_warning >= 0 && var.error_rate_warning <= 1
    error_message = "error_rate_warning must be between 0 and 1."
  }
}

variable "error_rate_critical" {
  description = "5xx error rate threshold for CRITICAL alerts (0.05 = 5%)."
  type        = number
  default     = 0.05

  validation {
    condition     = var.error_rate_critical >= 0 && var.error_rate_critical <= 1
    error_message = "error_rate_critical must be between 0 and 1."
  }
}

# ------------------------------------------------------------------------------
# Timing Configuration
# ------------------------------------------------------------------------------

variable "alert_duration_seconds" {
  description = "How long a condition must persist before alerting (prevents flapping)."
  type        = number
  default     = 300

  validation {
    condition     = var.alert_duration_seconds >= 60 && var.alert_duration_seconds <= 3600
    error_message = "alert_duration_seconds must be between 60 and 3600 seconds."
  }
}
