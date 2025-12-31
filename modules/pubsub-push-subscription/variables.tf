# Required variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region where Cloud Run service is deployed"
  type        = string
}

variable "name" {
  description = "Base name for the subscription (resources will be named: {name}, {name}-dlq, {name}-dlq-monitoring)"
  type        = string
}

variable "service_account_id" {
  description = "Service account ID for Pub/Sub invoker (6-30 characters, lowercase letters, numbers, hyphens)"
  type        = string
}

variable "topic_id" {
  description = "ID of the Pub/Sub topic to subscribe to"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service to push messages to"
  type        = string
}

variable "cloud_run_service_url" {
  description = "URL of the Cloud Run service"
  type        = string
}

variable "push_endpoint_path" {
  description = "HTTP path for the push endpoint on the Cloud Run service"
  type        = string
  default     = "/pubsub/push"
}

# Subscription configuration
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

# Dead Letter Queue configuration
variable "dlq_message_retention_duration" {
  description = "How long to retain messages in the DLQ"
  type        = string
  default     = "604800s" # 7 days
}

# Optional
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
