locals {
  # Common labels for alert routing
  base_labels = {
    service = var.service_name
    region  = var.region
    type    = "golden_signals"
  }

  # Console URL base for documentation links
  console_base = "https://console.cloud.google.com"
  run_url      = "${local.console_base}/run/detail/${var.region}/${var.service_name}"
  logs_url     = "${local.run_url}/logs?project=${var.project_id}"
  metrics_url  = "${local.run_url}/metrics?project=${var.project_id}"
  errors_url   = "${local.console_base}/errors?project=${var.project_id}&service=${var.service_name}"
}

# ==============================================================================
# 1. LATENCY ALERTS (P95)
# ==============================================================================

resource "google_monitoring_alert_policy" "latency_critical" {
  count = var.enable_latency_alerts ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.service_name} - Latency P95 > ${var.latency_critical_ms}ms"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels
  user_labels = merge(local.base_labels, { severity = "critical" })

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: High Latency
      **Service:** ${var.service_name}
      **Threshold:** P95 latency > ${var.latency_critical_ms}ms

      ### Playbook
      1. Check [CPU/Memory](${local.metrics_url})
      2. Review [Logs](${local.logs_url})
      3. Check downstream DBs or APIs.
    EOT
  }

  conditions {
    display_name = "P95 Latency > ${var.latency_critical_ms}ms"
    condition_threshold {
      filter = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.service_name}\" AND resource.labels.location = \"${var.region}\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration        = "${var.alert_duration_seconds}s"
      comparison      = "COMPARISON_GT"
      # Metric is in microseconds, convert from ms
      threshold_value = var.latency_critical_ms * 1000
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "latency_warning" {
  count = var.enable_latency_alerts ? 1 : 0

  project      = var.project_id
  display_name = "[WARNING] ${var.service_name} - Latency P95 > ${var.latency_warning_ms}ms"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.warning_notification_channels
  user_labels = merge(local.base_labels, { severity = "warning" })

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Warning: Elevated Latency
      **Service:** ${var.service_name}
      **Threshold:** P95 latency > ${var.latency_warning_ms}ms
      
      Review [metrics dashboard](${local.metrics_url}) for trends.
    EOT
  }

  conditions {
    display_name = "P95 Latency > ${var.latency_warning_ms}ms"
    condition_threshold {
      filter = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${var.service_name}\" AND resource.labels.location = \"${var.region}\" AND metric.type = \"run.googleapis.com/request_latencies\""
      duration        = "${var.alert_duration_seconds}s"
      comparison      = "COMPARISON_GT"
      # Metric is in microseconds, convert from ms
      threshold_value = var.latency_warning_ms * 1000
      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_DELTA"
        cross_series_reducer = "REDUCE_PERCENTILE_95"
      }
    }
  }
}

# ==============================================================================
# 2. ERROR RATE ALERTS (5xx)
# ==============================================================================

resource "google_monitoring_alert_policy" "errors_critical" {
  count = var.enable_error_alerts ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.service_name} - Error Rate > ${format("%.1f", var.error_rate_critical * 100)}%"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels
  user_labels = merge(local.base_labels, { severity = "critical" })

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: High Error Rate
      **Service:** ${var.service_name}
      **Threshold:** 5xx > ${format("%.1f", var.error_rate_critical * 100)}%

      ### Playbook
      1. Check [Error Reporting](${local.errors_url})
      2. Review [Logs](${local.logs_url}) filtered by `severity>=ERROR`
    EOT
  }

  conditions {
    display_name = "5xx Error Rate > ${format("%.1f", var.error_rate_critical * 100)}%"
    condition_monitoring_query_language {
      duration = "${var.alert_duration_seconds}s"
      query = <<-EOT
        fetch cloud_run_revision
        | metric 'run.googleapis.com/request_count'
        | filter (resource.service_name == '${var.service_name}') && (resource.location == '${var.region}')
        | align rate(1m)
        | group_by [resource.service_name], [ratio: sum(if(metric.response_code_class == '5xx', val(), 0.0)) / sum(val())]
        | condition ratio > ${var.error_rate_critical}
      EOT
    }
  }
}

resource "google_monitoring_alert_policy" "errors_warning" {
  count = var.enable_error_alerts ? 1 : 0

  project      = var.project_id
  display_name = "[WARNING] ${var.service_name} - Error Rate > ${format("%.1f", var.error_rate_warning * 100)}%"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.warning_notification_channels
  user_labels = merge(local.base_labels, { severity = "warning" })

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Warning: Elevated Error Rate
      **Service:** ${var.service_name}
      **Threshold:** 5xx > ${format("%.1f", var.error_rate_warning * 100)}%
      
      Review logs for potential issues.
    EOT
  }

  conditions {
    display_name = "5xx Error Rate > ${format("%.1f", var.error_rate_warning * 100)}%"
    condition_monitoring_query_language {
      duration = "${var.alert_duration_seconds}s"
      query = <<-EOT
        fetch cloud_run_revision
        | metric 'run.googleapis.com/request_count'
        | filter (resource.service_name == '${var.service_name}') && (resource.location == '${var.region}')
        | align rate(1m)
        | group_by [resource.service_name], [ratio: sum(if(metric.response_code_class == '5xx', val(), 0.0)) / sum(val())]
        | condition ratio > ${var.error_rate_warning}
      EOT
    }
  }
}

