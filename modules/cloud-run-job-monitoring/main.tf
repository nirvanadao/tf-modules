# ==============================================================================
# Cloud Run Job Monitoring
# ==============================================================================
#
# Monitors Cloud Run Jobs for failures. Two alerting strategies:
#
#   1. Any Failure (default): Alert on every failed execution
#   2. Consecutive Failures: Alert after N failures in a row
#
# ==============================================================================

locals {
  console_base   = "https://console.cloud.google.com"
  job_url        = "${local.console_base}/run/jobs/details/${var.region}/${var.job_name}?project=${var.project_id}"
  logs_url       = "${local.console_base}/run/jobs/details/${var.region}/${var.job_name}/logs?project=${var.project_id}"
  executions_url = "${local.console_base}/run/jobs/details/${var.region}/${var.job_name}/executions?project=${var.project_id}"
}

# ------------------------------------------------------------------------------
# Alert: Any Job Failure
# ------------------------------------------------------------------------------
# Triggers immediately when any job execution fails. Best for critical jobs
# where every failure matters.

resource "google_monitoring_alert_policy" "job_failure" {
  count = var.alert_on_any_failure ? 1 : 0

  project      = var.project_id
  display_name = "[CRITICAL] ${var.job_name} - Job Execution Failed"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.notification_channels

  user_labels = {
    job      = var.job_name
    region   = var.region
    severity = "critical"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Cloud Run Job Failed

      **Job:** ${var.job_name}
      **Region:** ${var.region}

      ### Impact
      A scheduled or triggered job execution has failed. Check if this affects
      downstream systems or data pipelines.

      ### Playbook
      1. View [failed executions](${local.executions_url}) to identify the failure
      2. Check [execution logs](${local.logs_url}) for error details
      3. Review the exit code and error message
      4. Re-run the job manually if needed after fixing the issue

      ### Quick Commands
      ```bash
      # View recent executions
      gcloud run jobs executions list --job=${var.job_name} --region=${var.region} --project=${var.project_id}

      # View logs for latest execution
      gcloud logging read "resource.type=cloud_run_job AND resource.labels.job_name=${var.job_name}" --limit=100 --project=${var.project_id}

      # Re-run the job
      gcloud run jobs execute ${var.job_name} --region=${var.region} --project=${var.project_id}
      ```
    EOT
  }

  conditions {
    display_name = "Job execution failed"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"cloud_run_job\"",
        "resource.labels.job_name = \"${var.job_name}\"",
        "resource.labels.location = \"${var.region}\"",
        "metric.type = \"run.googleapis.com/job/completed_execution_count\"",
        "metric.labels.result = \"failed\""
      ])

      duration        = "0s" # Alert immediately
      comparison      = "COMPARISON_GT"
      threshold_value = 0

      aggregations {
        alignment_period     = "60s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }

      trigger {
        count = 1
      }
    }
  }
}

# ------------------------------------------------------------------------------
# Alert: Consecutive Failures
# ------------------------------------------------------------------------------
# Triggers after multiple failures within the evaluation window. Better for
# jobs that occasionally fail but retry successfully.

resource "google_monitoring_alert_policy" "job_consecutive_failures" {
  count = var.alert_on_consecutive_failures ? 1 : 0

  project      = var.project_id
  display_name = "[WARNING] ${var.job_name} - Multiple Job Failures (${var.consecutive_failure_threshold}+)"
  combiner     = "OR"
  enabled      = true

  notification_channels = var.notification_channels

  user_labels = {
    job      = var.job_name
    region   = var.region
    severity = "warning"
  }

  documentation {
    mime_type = "text/markdown"
    content   = <<-EOT
      ## Multiple Job Failures

      **Job:** ${var.job_name}
      **Region:** ${var.region}
      **Threshold:** ${var.consecutive_failure_threshold}+ failures in ${var.evaluation_window_minutes} minutes

      ### Impact
      The job has failed multiple times recently, indicating a persistent issue
      rather than a transient failure.

      ### Playbook
      1. View [recent executions](${local.executions_url}) to see failure pattern
      2. Check [logs](${local.logs_url}) for common error across failures
      3. Investigate if external dependencies are down
      4. Consider pausing the job schedule until fixed

      ### Quick Commands
      ```bash
      # View recent executions with status
      gcloud run jobs executions list --job=${var.job_name} --region=${var.region} --project=${var.project_id} --limit=10

      # Check if job is scheduled
      gcloud scheduler jobs list --project=${var.project_id} --filter="name~${var.job_name}"
      ```
    EOT
  }

  conditions {
    display_name = "${var.consecutive_failure_threshold}+ failures in ${var.evaluation_window_minutes}m"

    condition_threshold {
      filter = join(" AND ", [
        "resource.type = \"cloud_run_job\"",
        "resource.labels.job_name = \"${var.job_name}\"",
        "resource.labels.location = \"${var.region}\"",
        "metric.type = \"run.googleapis.com/job/completed_execution_count\"",
        "metric.labels.result = \"failed\""
      ])

      duration        = "${var.evaluation_window_minutes * 60}s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.consecutive_failure_threshold - 1

      aggregations {
        alignment_period     = "${var.evaluation_window_minutes * 60}s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }
}
