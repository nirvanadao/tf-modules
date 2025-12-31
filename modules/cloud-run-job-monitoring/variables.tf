# ==============================================================================
# Cloud Run Job Monitoring - Variables
# ==============================================================================
# Simple monitoring for Cloud Run Jobs. Alerts when jobs fail.
# ==============================================================================

variable "project_id" {
  description = "The Google Cloud project ID."
  type        = string
}

variable "job_name" {
  description = "The exact name of the Cloud Run Job to monitor."
  type        = string
}

variable "region" {
  description = "The region where the Cloud Run Job is deployed (e.g., 'us-central1')."
  type        = string
}

variable "notification_channels" {
  description = "Notification channel IDs for alerts."
  type        = list(string)
  default     = []
}

variable "alert_on_any_failure" {
  description = "Alert immediately on any job failure (recommended for critical jobs)."
  type        = bool
  default     = true
}

variable "alert_on_consecutive_failures" {
  description = "Alert after multiple consecutive failures (reduces noise for flaky jobs)."
  type        = bool
  default     = false
}

variable "consecutive_failure_threshold" {
  description = "Number of consecutive failures before alerting (when alert_on_consecutive_failures is true)."
  type        = number
  default     = 3

  validation {
    condition     = var.consecutive_failure_threshold >= 2
    error_message = "consecutive_failure_threshold must be at least 2."
  }
}

variable "evaluation_window_minutes" {
  description = "Time window in minutes to evaluate for failures."
  type        = number
  default     = 60

  validation {
    condition     = var.evaluation_window_minutes >= 5 && var.evaluation_window_minutes <= 1440
    error_message = "evaluation_window_minutes must be between 5 and 1440 (24 hours)."
  }
}
