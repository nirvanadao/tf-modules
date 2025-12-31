# Subscription outputs
output "subscription_name" {
  description = "Name of the Pub/Sub push subscription"
  value       = google_pubsub_subscription.push_subscription.name
}

output "subscription_id" {
  description = "ID of the Pub/Sub push subscription"
  value       = google_pubsub_subscription.push_subscription.id
}

# DLQ outputs
output "dlq_topic_name" {
  description = "Name of the dead letter queue topic"
  value       = google_pubsub_topic.dlq.name
}

output "dlq_topic_id" {
  description = "ID of the dead letter queue topic"
  value       = google_pubsub_topic.dlq.id
}

output "dlq_monitoring_subscription_name" {
  description = "Name of the DLQ monitoring subscription"
  value       = google_pubsub_subscription.dlq_monitoring.name
}

output "dlq_monitoring_subscription_id" {
  description = "ID of the DLQ monitoring subscription"
  value       = google_pubsub_subscription.dlq_monitoring.id
}

# Service account outputs
output "pubsub_invoker_email" {
  description = "Email of the Pub/Sub invoker service account"
  value       = google_service_account.pubsub_invoker.email
}

output "pubsub_invoker_id" {
  description = "ID of the Pub/Sub invoker service account"
  value       = google_service_account.pubsub_invoker.id
}
