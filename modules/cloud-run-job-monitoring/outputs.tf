# ==============================================================================
# Cloud Run Job Monitoring - Outputs
# ==============================================================================

output "failure_alert_id" {
  description = "The ID of the job failure alert policy."
  value       = var.alert_on_any_failure ? google_monitoring_alert_policy.job_failure[0].name : null
}

output "consecutive_failures_alert_id" {
  description = "The ID of the consecutive failures alert policy."
  value       = var.alert_on_consecutive_failures ? google_monitoring_alert_policy.job_consecutive_failures[0].name : null
}
