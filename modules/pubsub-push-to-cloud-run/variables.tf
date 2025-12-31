# ==============================================================================
# Required Variables
# ==============================================================================

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for Cloud Run service"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service (also used for subscription naming)"
  type        = string
}

variable "initial_image" {
  description = "Initial Docker image URL (ignored after first deployment)"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC Access Connector ID for connecting to VPC resources"
  type        = string
}

variable "topic_id" {
  description = "ID of the Pub/Sub topic to subscribe to"
  type        = string
}

# ==============================================================================
# Cloud Run Configuration
# ==============================================================================

variable "environment_variables" {
  description = "Environment variables for the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables (name -> Secret Manager resource path)"
  type        = map(string)
  default     = {}
}

variable "service_account_roles" {
  description = "List of IAM roles to grant to the service account"
  type        = list(string)
  default     = []
}

variable "cpu" {
  description = "CPU allocation for the Cloud Run service"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for the Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "max_request_concurrency" {
  description = "Maximum concurrent requests per container instance"
  type        = number
  default     = 80
}

variable "liveness_probe_path" {
  description = "HTTP path for liveness probe (null to disable)"
  type        = string
  default     = "/healthz"
}

variable "liveness_probe_initial_delay_seconds" {
  description = "Initial delay before liveness probe starts"
  type        = number
  default     = 0
}

variable "liveness_probe_period_seconds" {
  description = "How often to perform the liveness probe"
  type        = number
  default     = 10
}

variable "liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe"
  type        = number
  default     = 1
}

variable "liveness_probe_failure_threshold" {
  description = "Number of failures before marking container as unhealthy"
  type        = number
  default     = 3
}

# ==============================================================================
# Pub/Sub Subscription Configuration
# ==============================================================================

variable "push_endpoint_path" {
  description = "HTTP path for the push endpoint on Cloud Run"
  type        = string
  default     = "/pubsub/push"
}

variable "ack_deadline_seconds" {
  description = "Ack deadline for the subscription in seconds"
  type        = number
  default     = 60
}

variable "message_retention_duration" {
  description = "How long to retain unacknowledged messages"
  type        = string
  default     = "604800s" # 7 days
}

variable "retry_minimum_backoff" {
  description = "Minimum backoff for retries"
  type        = string
  default     = "10s"
}

variable "retry_maximum_backoff" {
  description = "Maximum backoff for retries"
  type        = string
  default     = "600s"
}

variable "max_delivery_attempts" {
  description = "Maximum delivery attempts before sending to DLQ"
  type        = number
  default     = 5
}

variable "dlq_message_retention_duration" {
  description = "How long to retain messages in the DLQ"
  type        = string
  default     = "604800s" # 7 days
}

# ==============================================================================
# Monitoring Configuration
# ==============================================================================

variable "enable_monitoring" {
  description = "Enable monitoring alerts (both Pub/Sub and Cloud Run)"
  type        = bool
  default     = true
}

variable "critical_notification_channels" {
  description = "Notification channels for CRITICAL alerts"
  type        = list(string)
  default     = []
}

variable "warning_notification_channels" {
  description = "Notification channels for WARNING/INFO alerts"
  type        = list(string)
  default     = []
}

# --- Pub/Sub Monitoring ---

variable "enable_dlq_alert" {
  description = "Enable DLQ breach alert"
  type        = bool
  default     = true
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
  description = "P95 Pub/Sub delivery latency threshold in ms"
  type        = number
  default     = 2000
}

# --- Cloud Run Monitoring ---

variable "enable_latency_alerts" {
  description = "Enable Cloud Run latency monitoring alerts"
  type        = bool
  default     = true
}

variable "enable_error_alerts" {
  description = "Enable Cloud Run 5xx error rate monitoring alerts"
  type        = bool
  default     = true
}

variable "latency_warning_ms" {
  description = "P95 latency threshold in ms for WARNING (higher for workers)"
  type        = number
  default     = 5000 # 5s - workers typically process longer than APIs
}

variable "latency_critical_ms" {
  description = "P95 latency threshold in ms for CRITICAL (higher for workers)"
  type        = number
  default     = 30000 # 30s - workers can take longer
}

variable "error_rate_warning" {
  description = "5xx error rate threshold for WARNING (0.01 = 1%)"
  type        = number
  default     = 0.01
}

variable "error_rate_critical" {
  description = "5xx error rate threshold for CRITICAL (0.05 = 5%)"
  type        = number
  default     = 0.05
}

variable "alert_duration_seconds" {
  description = "How long a condition must persist before alerting"
  type        = number
  default     = 300
}

# ==============================================================================
# Labels
# ==============================================================================

variable "labels" {
  description = "Labels to apply to Pub/Sub resources"
  type        = map(string)
  default     = {}
}
