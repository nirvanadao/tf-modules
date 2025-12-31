# ==============================================================================
# Cloud Run Outputs
# ==============================================================================

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = module.cloud_run_service.service_name
}

output "service_id" {
  description = "ID of the Cloud Run service"
  value       = module.cloud_run_service.service_id
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = module.cloud_run_service.service_url
}

output "service_account_email" {
  description = "Email of the service account used by Cloud Run"
  value       = module.cloud_run_service.service_account_email
}

output "service_account_id" {
  description = "ID of the service account"
  value       = module.cloud_run_service.service_account_id
}

# ==============================================================================
# Pub/Sub Subscription Outputs
# ==============================================================================

output "subscription_name" {
  description = "Name of the Pub/Sub push subscription"
  value       = module.pubsub_push_subscription.subscription_name
}

output "subscription_id" {
  description = "ID of the Pub/Sub push subscription"
  value       = module.pubsub_push_subscription.subscription_id
}

# ==============================================================================
# Dead Letter Queue Outputs
# ==============================================================================

output "dlq_topic_name" {
  description = "Name of the dead letter queue topic"
  value       = module.pubsub_push_subscription.dlq_topic_name
}

output "dlq_topic_id" {
  description = "ID of the dead letter queue topic"
  value       = module.pubsub_push_subscription.dlq_topic_id
}

output "dlq_monitoring_subscription_name" {
  description = "Name of the DLQ monitoring subscription"
  value       = module.pubsub_push_subscription.dlq_monitoring_subscription_name
}

output "dlq_monitoring_subscription_id" {
  description = "ID of the DLQ monitoring subscription"
  value       = module.pubsub_push_subscription.dlq_monitoring_subscription_id
}

# ==============================================================================
# Invoker Service Account
# ==============================================================================

output "pubsub_invoker_email" {
  description = "Email of the Pub/Sub invoker service account"
  value       = module.pubsub_push_subscription.pubsub_invoker_email
}

output "pubsub_invoker_id" {
  description = "ID of the Pub/Sub invoker service account"
  value       = module.pubsub_push_subscription.pubsub_invoker_id
}
