terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  common_labels = merge(
    {
      managed_by = "terraform"
    },
    var.labels
  )
}

# Main Pub/Sub Topic
resource "google_pubsub_topic" "topic" {
  name    = var.name
  project = var.project_id

  labels = local.common_labels

  message_retention_duration = var.message_retention_duration
}

# Monitoring Subscription (if enabled)
resource "google_pubsub_subscription" "monitoring" {
  count   = var.enable_monitoring_subscription ? 1 : 0
  name    = "${var.name}-monitoring"
  topic   = google_pubsub_topic.topic.name
  project = var.project_id

  labels = merge(
    local.common_labels,
    {
      purpose = "monitoring"
    }
  )

  # Acknowledgment deadline
  ack_deadline_seconds = var.monitoring_ack_deadline_seconds

  # Message retention for unacknowledged messages
  message_retention_duration = var.monitoring_message_retention_duration

  # Retain acknowledged messages for debugging
  retain_acked_messages = var.monitoring_retain_acked_messages

  # Expiration policy - subscription expires if inactive
  expiration_policy {
    ttl = var.monitoring_expiration_ttl
  }

  # Retry policy
  retry_policy {
    minimum_backoff = var.retry_minimum_backoff
    maximum_backoff = var.retry_maximum_backoff
  }
}
