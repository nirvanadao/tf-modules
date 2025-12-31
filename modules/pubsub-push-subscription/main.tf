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

# Get project data to access project number for Pub/Sub service account
data "google_project" "project" {
  project_id = var.project_id
}

locals {
  pubsub_service_account = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# Dead Letter Queue Topic for this subscription
resource "google_pubsub_topic" "dlq" {
  project = var.project_id
  name    = "${var.name}-dlq"

  labels = merge(
    local.common_labels,
    {
      purpose = "dead-letter-queue"
    }
  )

  message_retention_duration = var.dlq_message_retention_duration
}

# Grant Pub/Sub service account permission to publish to DLQ
resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.publisher"
  member  = local.pubsub_service_account
}

# Grant Pub/Sub service account permission to subscribe to DLQ (required for dead lettering)
resource "google_pubsub_topic_iam_member" "dlq_subscriber" {
  project = var.project_id
  topic   = google_pubsub_topic.dlq.name
  role    = "roles/pubsub.subscriber"
  member  = local.pubsub_service_account
}

# DLQ Monitoring Subscription
resource "google_pubsub_subscription" "dlq_monitoring" {
  project = var.project_id
  name    = "${var.name}-dlq-monitoring"
  topic   = google_pubsub_topic.dlq.name

  labels = merge(
    local.common_labels,
    {
      purpose = "dlq-monitoring"
    }
  )

  # Long acknowledgment deadline for manual inspection
  ack_deadline_seconds = 600

  # Retain messages for a long time for debugging
  message_retention_duration = "604800s" # 7 days

  # Retain acknowledged messages
  retain_acked_messages = true

  # Never expire the DLQ monitoring subscription
  expiration_policy {
    ttl = "" # Never expire
  }
}

# Service account for Pub/Sub to invoke Cloud Run
resource "google_service_account" "pubsub_invoker" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Pub/Sub invoker for ${var.name}"
}

# Grant the Pub/Sub service account permission to invoke Cloud Run
resource "google_cloud_run_v2_service_iam_member" "pubsub_invoker" {
  project  = var.project_id
  location = var.region
  name     = var.cloud_run_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.pubsub_invoker.email}"
}

# Push Subscription to Cloud Run
resource "google_pubsub_subscription" "push_subscription" {
  project = var.project_id
  name    = var.name
  topic   = var.topic_id

  # Push configuration to Cloud Run
  push_config {
    push_endpoint = "${var.cloud_run_service_url}${var.push_endpoint_path}"

    # Authenticate as a service account
    oidc_token {
      service_account_email = google_service_account.pubsub_invoker.email
    }

    attributes = {
      x-goog-version = "v1"
    }
  }

  # Ack deadline
  ack_deadline_seconds = var.ack_deadline_seconds

  # Message retention
  message_retention_duration = var.message_retention_duration

  # Retry policy with exponential backoff
  retry_policy {
    minimum_backoff = var.retry_minimum_backoff
    maximum_backoff = var.retry_maximum_backoff
  }

  # Dead letter queue configuration
  dead_letter_policy {
    dead_letter_topic     = google_pubsub_topic.dlq.id
    max_delivery_attempts = var.max_delivery_attempts
  }

  # Labels
  labels = local.common_labels

  depends_on = [
    google_cloud_run_v2_service_iam_member.pubsub_invoker
  ]
}

# Grant Pub/Sub service account subscriber role at project level
# This ensures all push subscriptions (including those with DLQs) work correctly
resource "google_project_iam_member" "pubsub_subscriber" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"
  member  = local.pubsub_service_account
}
