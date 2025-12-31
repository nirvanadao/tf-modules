# ==============================================================================
# Public Cloud Run Uptime Check - Outputs
# ==============================================================================

output "uptime_check_id" {
  description = "The ID of the uptime check."
  value       = var.enable_uptime_check ? google_monitoring_uptime_check_config.https_check[0].uptime_check_id : null
}

output "uptime_check_name" {
  description = "The full resource name of the uptime check."
  value       = var.enable_uptime_check ? google_monitoring_uptime_check_config.https_check[0].name : null
}

output "uptime_failure_alert_id" {
  description = "The ID of the uptime failure alert policy."
  value       = var.enable_uptime_check ? google_monitoring_alert_policy.uptime_failure[0].name : null
}

