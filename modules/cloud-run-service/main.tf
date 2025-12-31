# Cloud Run service
resource "google_cloud_run_v2_service" "service" {
  project  = var.project_id
  location = var.region
  name     = var.service_name

  ingress = var.ingress

  template {
    service_account = google_service_account.service.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }


    # Dynamic VPC Access: Only configures if a connector ID is provided
    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = "PRIVATE_RANGES_ONLY"
      }
    }

    timeout = "${var.timeout_seconds}s"

    # Maximum concurrent requests per container instance
    max_instance_request_concurrency = var.max_request_concurrency

    containers {
      image = var.initial_image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
      }

      # Liveness Probe (Optional but recommended)
      dynamic "liveness_probe" {
        for_each = var.liveness_probe_path != null ? [1] : []
        content {
          http_get {
            path = var.liveness_probe_path
          }
          initial_delay_seconds = var.liveness_probe_initial_delay_seconds
          period_seconds        = var.liveness_probe_period_seconds
          timeout_seconds       = var.liveness_probe_timeout_seconds
          failure_threshold     = var.liveness_probe_failure_threshold
        }
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

  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
      template[0].labels,
    ]
  }
}
