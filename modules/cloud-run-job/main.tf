# Cloud Run job
resource "google_cloud_run_v2_job" "job" {
  project  = var.project_id
  location = var.region
  name     = var.job_name

  template {
    task_count = var.task_count

    template {
      service_account = google_service_account.job.email

      vpc_access {
        connector = var.vpc_connector_id
        egress    = "PRIVATE_RANGES_ONLY"
      }

      timeout     = "${var.timeout_seconds}s"
      max_retries = var.max_retries

      containers {
        image = var.initial_image

        resources {
          limits = {
            cpu    = var.cpu
            memory = var.memory
          }
        }

        env {
          name  = "NODE_ENV"
          value = "production"
        }

        dynamic "env" {
          for_each = var.environment_variables
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secret_environment_variables
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value
                version = "latest"
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

# Cloud Scheduler job to trigger the Cloud Run job
resource "google_cloud_scheduler_job" "scheduler" {
  project   = var.project_id
  region    = var.region
  name      = "${var.job_name}-scheduler"
  schedule  = var.cron_schedule
  time_zone = var.time_zone
  paused    = var.scheduler_paused

  http_target {
    uri         = "https://${var.region}-run.googleapis.com/apis/run.googleapis.com/v1/namespaces/${var.project_id}/jobs/${google_cloud_run_v2_job.job.name}:run"
    http_method = "POST"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  retry_config {
    retry_count = 1
  }
}
