variable "notification_channels" {
  description = "List of Notification Channel IDs"
  type        = list(string)
}

# 1. WORKER SERVICE FAILURES (High Priority)
resource "google_monitoring_alert_policy" "worker_failures" {
  project      = var.project_id
  display_name = "${var.name} - Worker Failure (5xx)"
  combiner     = "OR"
  enabled      = true
  severity     = "CRITICAL"
  notification_channels = var.notification_channels

  conditions {
    display_name = "Worker returning 5xx errors"
    condition_threshold {
      # FIX: Changed 'request/count' to 'request_count'
      filter     = "resource.type = \"cloud_run_revision\" AND resource.label.service_name = \"${module.worker_service.service_name}\" AND metric.type = \"run.googleapis.com/request_count\" AND metric.label.response_code_class = \"5xx\""
      duration   = "60s" 
      comparison = "COMPARISON_GT"
      threshold_value = 0 

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "The Worker Service **${module.worker_service.service_name}** is throwing 500 errors."
  }
}

# 2. HEARTBEAT MISSING (Pipeline Stalled)
resource "google_monitoring_alert_policy" "worker_heartbeat" {
  project      = var.project_id
  display_name = "${var.name} - Pipeline Stalled (No Traffic)"
  combiner     = "OR"
  enabled      = true
  severity     = "CRITICAL"
  notification_channels = var.notification_channels

  conditions {
    display_name = "No requests received for 60s"
    condition_threshold {
      # FIX: Changed 'request/count' to 'request_count'
      filter     = "resource.type = \"cloud_run_revision\" AND resource.label.service_name = \"${module.worker_service.service_name}\" AND metric.type = \"run.googleapis.com/request_count\""
      duration   = "60s"
      comparison = "COMPARISON_LT"
      threshold_value = 0.01 

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  documentation {
    mime_type = "text/markdown"
    content   = "The Worker Service **${module.worker_service.service_name}** has received Zero requests in the last minute."
  }
}

# 3. SCHEDULER JOB FAILURES
resource "google_monitoring_alert_policy" "scheduler_failures" {
  project      = var.project_id
  display_name = "${var.name} - Scheduler Job Failed"
  combiner     = "OR"
  enabled      = true
  notification_channels = var.notification_channels

  conditions {
    display_name = "Job Execution Failed"
    condition_threshold {
      # Ensure using 'job/completed_execution_count' (This one typically uses slashes or underscores depending on API version, but 'run.googleapis.com/job/completed_execution_count' is standard)
      filter     = "resource.type = \"cloud_run_job\" AND resource.label.job_name = \"${module.scheduler_job.job_name}\" AND metric.type = \"run.googleapis.com/job/completed_execution_count\" AND metric.label.result = \"failed\""
      duration   = "0s" 
      comparison = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}

# 4. CLOUD TASKS QUEUE JAMMED
resource "google_monitoring_alert_policy" "queue_depth" {
  project      = var.project_id
  display_name = "${var.name} - Queue Backlog High"
  combiner     = "OR"
  enabled      = true
  notification_channels = var.notification_channels

  conditions {
    display_name = "Queue Depth > 1000"
    condition_threshold {
      filter     = "resource.type = \"cloud_tasks_queue\" AND resource.label.queue_id = \"${google_cloud_tasks_queue.queue.name}\" AND metric.type = \"cloudtasks.googleapis.com/queue/depth\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      threshold_value = 1000

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_MEAN"
      }
    }
  }
}