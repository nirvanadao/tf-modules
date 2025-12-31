# ==============================================================================
# Stream Sigs Monitoring
# ==============================================================================
# Provides alerts for the signature streaming pipeline:
# - Worker service errors (5xx)
# - Pipeline heartbeat (traffic flow)
# - Scheduler job failures
# - Queue backlog depth
# ==============================================================================

locals {
  # Console Deep Links
  console_base = "https://console.cloud.google.com"

  # Worker Service URLs
  worker_url      = "${local.console_base}/run/detail/${var.region}/${module.worker_service.service_name}?project=${var.project_id}"
  worker_logs_url = "${local.worker_url}/logs"
  worker_metrics_url = "${local.worker_url}/metrics"

  # Scheduler Job URLs
  scheduler_url = "${local.console_base}/run/jobs/details/${var.region}/${module.scheduler_job.job_name}?project=${var.project_id}"

  # Queue URLs
  queue_url = "${local.console_base}/cloudtasks/queue/${var.region}/${google_cloud_tasks_queue.queue.name}?project=${var.project_id}"

  # Common labels
  monitoring_labels = {
    component = "stream-sigs"
    pipeline  = var.name
  }
}

# ==============================================================================
# 1. WORKER SERVICE ERRORS
# ==============================================================================

resource "google_monitoring_alert_policy" "worker_errors_critical" {
  count = var.enable_worker_failure_alert ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.name} - Worker 5xx > ${var.worker_error_critical_threshold}/min"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels
  user_labels = merge(local.monitoring_labels, { severity = "critical" })

  alert_strategy {
    auto_close = "604800s" # 7 days
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: Worker Service Errors

      **Pipeline:** ${var.name}
      **Service:** ${module.worker_service.service_name}
      **Threshold:** > ${var.worker_error_critical_threshold} errors/min

      ### Playbook
      1. [View Worker Logs](${local.worker_logs_url}) - Filter by `severity>=ERROR`
      2. [View Worker Metrics](${local.worker_metrics_url}) - Check CPU/Memory
      3. Check Redis connectivity: `${var.redis_url}`
      4. Check Solana RPC health

      ### Common Causes
      - **Redis timeout:** Connection to Redis failed
      - **RPC errors:** Solana RPC returning errors
      - **Checkpoint failure:** Cannot read/write GCS checkpoint
    EOT
  }

  conditions {
    display_name = "5xx errors > ${var.worker_error_critical_threshold}/min"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${module.worker_service.service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      duration   = "${var.alert_duration_seconds}s"
      comparison = "COMPARISON_GT"
      threshold_value = var.worker_error_critical_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "worker_errors_warning" {
  count = var.enable_worker_failure_alert ? 1 : 0

  project      = var.project_id
  display_name = "[WARNING] ${var.name} - Worker 5xx > ${var.worker_error_threshold}/min"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.warning_notification_channels
  user_labels = merge(local.monitoring_labels, { severity = "warning" })

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Warning: Worker Service Errors

      **Pipeline:** ${var.name}
      **Service:** ${module.worker_service.service_name}
      **Threshold:** > ${var.worker_error_threshold} errors/min

      Review [worker logs](${local.worker_logs_url}) for potential issues.
    EOT
  }

  conditions {
    display_name = "5xx errors > ${var.worker_error_threshold}/min"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${module.worker_service.service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.labels.response_code_class = \"5xx\""
      duration   = "${var.alert_duration_seconds}s"
      comparison = "COMPARISON_GT"
      threshold_value = var.worker_error_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}

# ==============================================================================
# 2. PIPELINE HEARTBEAT (No Traffic)
# ==============================================================================

resource "google_monitoring_alert_policy" "heartbeat" {
  count = var.enable_heartbeat_alert ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.name} - Pipeline Stalled (No Traffic)"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels
  user_labels = merge(local.monitoring_labels, { severity = "critical" })

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: Pipeline Stalled

      **Pipeline:** ${var.name}
      **Worker:** ${module.worker_service.service_name}
      **Condition:** No requests received for ${var.heartbeat_missing_seconds}s

      ### Playbook
      1. [Check Scheduler Job](${local.scheduler_url}) - Is it running?
      2. [Check Queue](${local.queue_url}) - Are tasks being enqueued?
      3. [Check Worker Logs](${local.worker_logs_url}) - Any startup errors?

      ### Common Causes
      - **Scheduler paused:** Check if `scheduler_paused = true`
      - **Scheduler failing:** Job execution errors
      - **Queue stuck:** Tasks not being dispatched
      - **Worker crashed:** All instances terminated
    EOT
  }

  conditions {
    display_name = "No traffic for ${var.heartbeat_missing_seconds}s"
    condition_absent {
      filter   = "resource.type = \"cloud_run_revision\" AND resource.labels.service_name = \"${module.worker_service.service_name}\" AND metric.type = \"run.googleapis.com/request_count\""
      duration = "${var.heartbeat_missing_seconds}s"

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}

# ==============================================================================
# 3. SCHEDULER JOB FAILURES
# ==============================================================================

resource "google_monitoring_alert_policy" "scheduler_failure" {
  count = var.enable_scheduler_failure_alert ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.name} - Scheduler Job Failed"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels
  user_labels = merge(local.monitoring_labels, { severity = "critical" })

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: Scheduler Job Failed

      **Pipeline:** ${var.name}
      **Job:** ${module.scheduler_job.job_name}

      ### Playbook
      1. [View Job Executions](${local.scheduler_url}) - Check recent runs
      2. View execution logs for error details
      3. Manually trigger job to test

      ### Common Causes
      - **Queue permission:** Cannot enqueue tasks
      - **Network error:** Cannot reach Cloud Tasks API
      - **Configuration error:** Invalid environment variables
    EOT
  }

  conditions {
    display_name = "Job execution failed"
    condition_threshold {
      filter     = "resource.type = \"cloud_run_job\" AND resource.labels.job_name = \"${module.scheduler_job.job_name}\" AND metric.type = \"run.googleapis.com/job/completed_execution_count\" AND metric.labels.result = \"failed\""
      duration   = "0s"
      comparison = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}

# ==============================================================================
# 4. QUEUE DEPTH (Backlog)
# ==============================================================================

resource "google_monitoring_alert_policy" "queue_depth_critical" {
  count = var.enable_queue_depth_alert ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.name} - Queue Backlog > ${var.queue_depth_critical_threshold}"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.critical_notification_channels
  user_labels = merge(local.monitoring_labels, { severity = "critical" })

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Critical: Queue Backlog

      **Pipeline:** ${var.name}
      **Queue:** ${google_cloud_tasks_queue.queue.name}
      **Threshold:** > ${var.queue_depth_critical_threshold} tasks

      ### Playbook
      1. [View Queue](${local.queue_url}) - Check task count and rate
      2. [View Worker Metrics](${local.worker_metrics_url}) - Check instance count
      3. Consider increasing `worker_max_instances`

      ### Common Causes
      - **Worker too slow:** Processing time > task interval
      - **Worker failing:** Tasks retrying repeatedly
      - **Max instances hit:** Cannot scale further
    EOT
  }

  conditions {
    display_name = "Queue depth > ${var.queue_depth_critical_threshold}"
    condition_threshold {
      filter     = "resource.type = \"cloud_tasks_queue\" AND resource.labels.queue_id = \"${google_cloud_tasks_queue.queue.name}\" AND metric.type = \"cloudtasks.googleapis.com/queue/depth\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = var.queue_depth_critical_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }
}

resource "google_monitoring_alert_policy" "queue_depth_warning" {
  count = var.enable_queue_depth_alert ? 1 : 0

  project      = var.project_id
  display_name = "[WARNING] ${var.name} - Queue Backlog > ${var.queue_depth_warning_threshold}"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.warning_notification_channels
  user_labels = merge(local.monitoring_labels, { severity = "warning" })

  alert_strategy {
    auto_close = "604800s"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Warning: Queue Backlog Growing

      **Pipeline:** ${var.name}
      **Queue:** ${google_cloud_tasks_queue.queue.name}
      **Threshold:** > ${var.queue_depth_warning_threshold} tasks

      Review [queue metrics](${local.queue_url}) and [worker capacity](${local.worker_metrics_url}).
    EOT
  }

  conditions {
    display_name = "Queue depth > ${var.queue_depth_warning_threshold}"
    condition_threshold {
      filter     = "resource.type = \"cloud_tasks_queue\" AND resource.labels.queue_id = \"${google_cloud_tasks_queue.queue.name}\" AND metric.type = \"cloudtasks.googleapis.com/queue/depth\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = var.queue_depth_warning_threshold

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }
}
