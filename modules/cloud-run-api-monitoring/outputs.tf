# ==============================================================================
# Cloud Run API Monitoring - Outputs
# ==============================================================================

output "latency_critical_alert_id" {
  description = "The ID of the critical latency alert policy."
  value       = var.enable_latency_alerts ? google_monitoring_alert_policy.latency_critical[0].name : null
}

output "latency_warning_alert_id" {
  description = "The ID of the warning latency alert policy."
  value       = var.enable_latency_alerts ? google_monitoring_alert_policy.latency_warning[0].name : null
}

output "errors_critical_alert_id" {
  description = "The ID of the critical error rate alert policy."
  value       = var.enable_error_alerts ? google_monitoring_alert_policy.errors_critical[0].name : null
}

output "errors_warning_alert_id" {
  description = "The ID of the warning error rate alert policy."
  value       = var.enable_error_alerts ? google_monitoring_alert_policy.errors_warning[0].name : null
}
