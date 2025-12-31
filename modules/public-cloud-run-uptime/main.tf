# ==============================================================================
# Public Cloud Run Uptime Check
# ==============================================================================
#
# Creates a global uptime check that verifies a public Cloud Run service is
# reachable from multiple geographic regions (USA, Europe, Asia Pacific).
#
# This catches total outages that internal monitoring might miss:
# - DNS failures
# - Load balancer misconfigurations
# - Certificate issues
# - Regional GCP outages
#
# ==============================================================================

locals {
  console_base = "https://console.cloud.google.com"

  # Extract hostname from URL for the uptime check
  service_host = replace(replace(var.service_url, "https://", ""), "http://", "")

  base_labels = {
    service = var.service_name
  }
}

# ------------------------------------------------------------------------------
# Global Uptime Check
# ------------------------------------------------------------------------------
# Checks the service from 3 global regions every minute (by default).

resource "google_monitoring_uptime_check_config" "https_check" {
  count = var.enable_uptime_check ? 1 : 0

  project      = var.project_id
  display_name = "${var.service_name} - Global Uptime Check"
  timeout      = "${var.timeout_seconds}s"
  period       = "${var.check_period_seconds}s"

  http_check {
    path           = var.health_check_path
    port           = 443
    use_ssl        = true
    validate_ssl   = true
    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }
  }

  # Optional content matching
  dynamic "content_matchers" {
    for_each = var.content_match_string != "" ? [1] : []
    content {
      content = var.content_match_string
      matcher = "CONTAINS_STRING"
    }
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = local.service_host
    }
  }

  # Check from 3 global regions to avoid false positives
  selected_regions = ["USA", "EUROPE", "ASIA_PACIFIC"]
}

# ------------------------------------------------------------------------------
# Uptime Failure Alert
# ------------------------------------------------------------------------------
# Alerts when the service is unreachable from multiple regions.

resource "google_monitoring_alert_policy" "uptime_failure" {
  count = var.enable_uptime_check ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.service_name} - Service Unreachable"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels

  user_labels = merge(local.base_labels, { severity = "critical" })

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: Service Unreachable

      **Service:** ${var.service_name}
      **URL:** ${var.service_url}
      **Health Check Path:** ${var.health_check_path}

      ### Impact
      The service is unreachable from the public internet. Users cannot access it.

      ### Playbook
      1. Check [Uptime Check Details](${local.console_base}/monitoring/uptime?project=${var.project_id})
      2. Verify the service is running: [Cloud Run Console](${local.console_base}/run?project=${var.project_id})
      3. Check DNS resolution: `nslookup ${local.service_host}`
      4. Check SSL certificate: `curl -vI ${var.service_url}`
      5. Review Load Balancer health (if applicable)

      ### Quick Commands
      ```bash
      # Test connectivity
      curl -I ${var.service_url}${var.health_check_path}

      # Check DNS
      nslookup ${local.service_host}

      # Verbose SSL check
      curl -vI ${var.service_url}
      ```

      ### Possible Causes
      - Cloud Run service crashed or scaled to zero with errors
      - DNS misconfiguration
      - SSL certificate expired or invalid
      - Load balancer health check failing
      - Regional GCP outage
    EOT
  }

  conditions {
    display_name = "Uptime check failing from ${var.failure_threshold_regions}+ regions"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"uptime_url\"",
        "metric.type = \"monitoring.googleapis.com/uptime_check/check_passed\"",
        "metric.labels.check_id = \"${google_monitoring_uptime_check_config.https_check[0].uptime_check_id}\""
      ])

      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.failure_threshold_regions - 1

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        group_by_fields      = ["resource.label.host"]
      }
    }
  }

  alert_strategy {
    auto_close = "1800s" # Auto-close after 30 minutes of recovery
  }
}
