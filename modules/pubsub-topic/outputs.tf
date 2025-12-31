# Topic outputs
output "topic_name" {
  description = "Name of the Pub/Sub topic"
  value       = google_pubsub_topic.topic.name
}

output "topic_id" {
  description = "ID of the Pub/Sub topic"
  value       = google_pubsub_topic.topic.id
}

# Monitoring subscription outputs
output "monitoring_subscription_name" {
  description = "Name of the monitoring subscription (empty if not enabled)"
  value       = var.enable_monitoring_subscription ? google_pubsub_subscription.monitoring[0].name : ""
}

output "monitoring_subscription_id" {
  description = "ID of the monitoring subscription (empty if not enabled)"
  value       = var.enable_monitoring_subscription ? google_pubsub_subscription.monitoring[0].id : ""
}
