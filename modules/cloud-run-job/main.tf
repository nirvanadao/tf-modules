# Cloud Run job
resource "google_cloud_run_v2_job" "job" {
  project  = var.project_id
  location = var.region
  name     = var.job_name

  template {
    task_count = var.task_count

    template {
      service_account = google_service_account.job.email

      dynamic "vpc_access" {
        for_each = var.vpc_connector_id != null || var.vpc_network != null || var.vpc_subnetwork != null ? [1] : []
        content {
          # Legacy: VPC Access Connector
          connector = var.vpc_connector_id

          # Modern: Direct VPC Egress
          dynamic "network_interfaces" {
            for_each = var.vpc_network != null || var.vpc_subnetwork != null ? [1] : []
            content {
              network    = var.vpc_network
              subnetwork = var.vpc_subnetwork
              tags       = var.vpc_network_tags
            }
          }

          egress = var.vpc_egress
        }
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
    precondition {
      condition     = !(var.vpc_connector_id != null && (var.vpc_network != null || var.vpc_subnetwork != null))
      error_message = "Cannot use both vpc_connector_id (legacy) and vpc_network/vpc_subnetwork (Direct VPC Egress). Choose one VPC connectivity method."
    }

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
