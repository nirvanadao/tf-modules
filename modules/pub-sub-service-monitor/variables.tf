variable "project_id" { type = string }
variable "region" { type = string }
variable "service_name" { type = string }

variable "main_push_subscription_id" {
  description = "The ID of the main push subscription"
  type        = string
}

variable "dlq_pull_subscription_id" {
  description = "The ID of the Dead Letter Queue subscription"
  type        = string
}

# --- Notification Channels ---

variable "critical_notification_channels" {
  description = "Channels for CRITICAL alerts (PagerDuty)"
  type        = list(string)
  default     = []
}

variable "warning_notification_channels" {
  description = "Channels for WARNING/INFO alerts (Slack)"
  type        = list(string)
  default     = []
}

# --- Alert Toggles ---

variable "enable_dlq_alert" {
  description = "Enable DLQ breach alert"
  type        = bool
  default     = true
}

# --- Thresholds ---

variable "ack_deadline_seconds" {
  description = "Ack deadline (for documentation only)"
  type        = number
  default     = 600
}

variable "push_error_threshold" {
  description = "Non-success responses per minute to trigger warning"
  type        = number
  default     = 10
}

variable "max_staleness_seconds" {
  description = "Age of oldest unacked message to trigger warning"
  type        = number
  default     = 1800
}

variable "delivery_latency_threshold_ms" {
  description = "P95 delivery latency threshold in ms"
  type        = number
  default     = 2000
}
