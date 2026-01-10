# ==============================================================================
# Pub/Sub Push Subscription Monitoring
# ==============================================================================

locals {
  # Console Deep Links
  console_base = "https://console.cloud.google.com"
  
  # Link to the Cloud Run Service Dashboard
  run_url = "${local.console_base}/run/detail/${var.region}/${var.service_name}?project=${var.project_id}"
  
  # Link to the Main Push Subscription Details
  sub_url = "${local.console_base}/cloudpubsub/subscription/detail/${var.main_push_subscription_id}?project=${var.project_id}"
  
  # Link to the DLQ Subscription Details
  dlq_url = "${local.console_base}/cloudpubsub/subscription/detail/${var.dlq_pull_subscription_id}?project=${var.project_id}"
}

# ---------------------------------------------------------
# 1. CRITICAL: DLQ Breach (The "0 Dead Letters" Rule)
# ---------------------------------------------------------
resource "google_monitoring_alert_policy" "dlq_breach" {
  count        = var.enable_dlq_alert ? 1 : 0
  project      = var.project_id
  display_name = "[CRITICAL] ${var.service_name} - DLQ Not Empty"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Messages waiting in DLQ"
    condition_threshold {
      filter = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${var.dlq_pull_subscription_id}\" AND metric.type = \"pubsub.googleapis.com/subscription/num_undelivered_messages\""
      
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  # USE CRITICAL CHANNELS (Pager)
  notification_channels = var.critical_notification_channels
  
  user_labels = {
    severity = "critical"
    service  = var.service_name
  }

  documentation {
    content = <<-EOT
      ## Critical: Dead Letters Detected

      **Service:** ${var.service_name}
      **DLQ:** `${var.dlq_pull_subscription_id}`

      ### 🚨 Immediate Actions
      1. [View DLQ Messages](${local.dlq_url}) - Inspect the `attributes` tab for error details.
      2. [View Service Logs](${local.run_url}/logs) - Check for 500s or application errors.

      ### Recovery
      **Once the root cause is fixed:**
      - Go to the [DLQ Subscription Page](${local.dlq_url})
      - Click **"Republish messages"** to send them back to the main topic.

      ### Common Causes
      - **Schema Mismatch:** JSON sent to Avro topic?
      - **Poison Pill:** 500 errors persisting past the retry policy.
      - **Timeout:** Processing took > ${var.ack_deadline_seconds}s.
    EOT
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------
# 2. WARNING: Push Failures (Non-ACK Responses)
# ---------------------------------------------------------
resource "google_monitoring_alert_policy" "push_failures" {
  project      = var.project_id
  display_name = "[WARNING] ${var.service_name} - Push Failures"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Push Error Count > ${var.push_error_threshold} / min"
    condition_threshold {
      filter = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${var.main_push_subscription_id}\" AND metric.type = \"pubsub.googleapis.com/subscription/push_request_count\" AND metric.labels.response_class != \"ack\""

      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.push_error_threshold

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM" 
      }
    }
  }

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  # USE WARNING CHANNELS (Slack/Email)
  notification_channels = var.warning_notification_channels
  user_labels = {
    severity = "warning"
    service  = var.service_name
  }

  documentation {
    content = <<-EOT
      ## Warning: High Failure Rate

      **Service:** ${var.service_name}
      **Subscription:** `${var.main_push_subscription_id}`
      **Threshold:** > ${var.push_error_threshold} errors/min

      ### 🔍 Investigation
      1. [View Subscription Metrics](${local.sub_url}) - Check the "Response codes" chart.
      2. [View Service Logs](${local.run_url}/logs) - Filter for `severity >= ERROR`.

      ### Common Response Codes
      - **429:** Too many requests. [Check Max Instances](${local.run_url}/details).
      - **503:** Service unavailable. Likely cold starts or crash loops.
      - **401/403:** IAM Permission issues. Check Service Account roles.
    EOT
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------
# 3. WARNING: Oldest Unacked Message (Staleness)
# ---------------------------------------------------------
resource "google_monitoring_alert_policy" "staleness" {
  project      = var.project_id
  display_name = "[WARNING] ${var.service_name} - Pipeline Stalled"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Oldest message age > ${var.max_staleness_seconds}s"
    condition_threshold {
      filter = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${var.main_push_subscription_id}\" AND metric.type = \"pubsub.googleapis.com/subscription/oldest_unacked_message_age\""

      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.max_staleness_seconds

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MAX"
      }
    }
  }

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  # USE WARNING CHANNELS (Slack/Email)
  notification_channels = var.warning_notification_channels
  user_labels = {
    severity = "warning"
    service  = var.service_name
  }

  documentation {
    content = <<-EOT
      ## Warning: Pipeline Stalled

      **Service:** ${var.service_name}
      **Staleness:** Oldest message is > ${var.max_staleness_seconds}s old.

      This indicates the consumer is either down, crashing, or processing much slower than ingestion.

      ### 🔍 Investigation
      1. [View Subscription Details](${local.sub_url}) - Check "Unacked message count".
      2. [View Service Metrics](${local.run_url}/metrics) - Is "Container Instance Count" hitting the limit?
      
      ### Troubleshooting
      - **Stuck Message:** One "poison pill" message might be retrying forever.
      - **Capacity:** Service might need higher `max_instances`.
      - **Dependency:** Is the database downstream accepting writes?
    EOT
    mime_type = "text/markdown"
  }
}

# ---------------------------------------------------------
# 4. INFO: Pub/Sub Delivery Latency
# ---------------------------------------------------------
resource "google_monitoring_alert_policy" "delivery_latency" {
  count        = var.enable_latency_alert ? 1 : 0
  project      = var.project_id
  display_name = "[INFO] ${var.service_name} - High Delivery Latency"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "P95 Delivery Latency > ${var.delivery_latency_threshold_ms}ms"
    condition_threshold {
      filter = "resource.type = \"pubsub_subscription\" AND resource.labels.subscription_id = \"${var.main_push_subscription_id}\" AND metric.type = \"pubsub.googleapis.com/subscription/push_request_latencies\""

      duration        = "300s"
      comparison      = "COMPARISON_GT"
      # Metric is in microseconds, convert from ms
      threshold_value = var.delivery_latency_threshold_ms * 1000

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_PERCENTILE_95"
        cross_series_reducer = "REDUCE_MAX"
      }
    }
  }

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  # USE WARNING CHANNELS (Slack/Email) - Info usually goes to the same place as warning
  notification_channels = var.warning_notification_channels
  user_labels = {
    severity = "info"
    service  = var.service_name
  }

  documentation {
    content = <<-EOT
      ## Info: High Delivery Latency

      **Service:** ${var.service_name}
      **Latency:** P95 > ${var.delivery_latency_threshold_ms}ms

      This measures the full round-trip from Pub/Sub's perspective.

      ### 🔍 Investigation
      1. [View Service Metrics](${local.run_url}/metrics) - Check CPU/Memory utilization.
      2. [View Traces](${local.console_base}/traces/list?project=${var.project_id}) - Look for slow spans in your application.
    EOT
    mime_type = "text/markdown"
  }
}