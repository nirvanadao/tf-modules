output "dlq_alert_id" {
  description = "ID of the DLQ breach alert policy"
  value       = var.enable_dlq_alert ? google_monitoring_alert_policy.dlq_breach[0].name : null
}

output "push_failures_alert_id" {
  description = "ID of the push failures alert policy"
  value       = google_monitoring_alert_policy.push_failures.name
}

output "staleness_alert_id" {
  description = "ID of the staleness alert policy"
  value       = google_monitoring_alert_policy.staleness.name
}

output "delivery_latency_alert_id" {
  description = "ID of the delivery latency alert policy"
  value       = google_monitoring_alert_policy.delivery_latency.name
}
