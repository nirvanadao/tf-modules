# Required variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Base name for the Pub/Sub topic (resources will be named: {name}, {name}-monitoring)"
  type        = string
}

# Optional topic configuration
variable "message_retention_duration" {
  description = "How long to retain unacknowledged messages in the topic"
  type        = string
  default     = "86400s" # 24 hours
}

variable "labels" {
  description = "Additional labels to apply to resources"
  type        = map(string)
  default     = {}
}

# Monitoring subscription configuration
variable "enable_monitoring_subscription" {
  description = "Whether to create a monitoring subscription"
  type        = bool
  default     = true
}

variable "monitoring_ack_deadline_seconds" {
  description = "Acknowledgment deadline for monitoring subscription"
  type        = number
  default     = 60
}

variable "monitoring_message_retention_duration" {
  description = "Message retention for monitoring subscription"
  type        = string
  default     = "604800s" # 7 days
}

variable "monitoring_retain_acked_messages" {
  description = "Whether to retain acknowledged messages in monitoring subscription"
  type        = bool
  default     = false
}

variable "monitoring_expiration_ttl" {
  description = "Subscription expires if inactive for this duration (empty string = never)"
  type        = string
  default     = "" # Never expire
}

# Retry policy configuration
variable "retry_minimum_backoff" {
  description = "Minimum backoff duration for retries"
  type        = string
  default     = "10s"
}

variable "retry_maximum_backoff" {
  description = "Maximum backoff duration for retries"
  type        = string
  default     = "600s" # 10 minutes
}
