# ==============================================================================
# Public Cloud Run Uptime Check - Variables
# ==============================================================================
# Global uptime monitoring for public Cloud Run services.
# Verifies the service is reachable from multiple geographic regions.
# ==============================================================================

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "service_name" {
  description = "The name of the Cloud Run service (used for display names)."
  type        = string
}

variable "service_url" {
  description = "The public HTTPS URL of the Cloud Run service to monitor."
  type        = string

  validation {
    condition     = can(regex("^https://", var.service_url))
    error_message = "service_url must start with https://"
  }
}

variable "health_check_path" {
  description = "The HTTP path to check (e.g., '/' or '/health')."
  type        = string
  default     = "/"
}

variable "check_period_seconds" {
  description = "How often to run the uptime check (60, 300, 600, or 900 seconds)."
  type        = number
  default     = 60

  validation {
    condition     = contains([60, 300, 600, 900], var.check_period_seconds)
    error_message = "check_period_seconds must be 60, 300, 600, or 900."
  }
}

variable "timeout_seconds" {
  description = "Timeout for the uptime check request."
  type        = number
  default     = 10

  validation {
    condition     = var.timeout_seconds >= 1 && var.timeout_seconds <= 60
    error_message = "timeout_seconds must be between 1 and 60."
  }
}

variable "enable_uptime_check" {
  description = "Enable the uptime check. Set to false to disable without removing."
  type        = bool
  default     = true
}

variable "critical_notification_channels" {
  description = "Notification channel IDs for critical alerts (uptime failures)."
  type        = list(string)
  default     = []
}

variable "failure_threshold_regions" {
  description = "Number of regions that must fail before alerting (1-3). Higher = fewer false positives."
  type        = number
  default     = 2

  validation {
    condition     = var.failure_threshold_regions >= 1 && var.failure_threshold_regions <= 3
    error_message = "failure_threshold_regions must be between 1 and 3."
  }
}

variable "content_match_string" {
  description = "Optional string that must appear in the response body. Leave empty to skip content matching."
  type        = string
  default     = ""
}
