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


    # Dynamic VPC Access: Supports both legacy VPC connectors and modern Direct VPC Egress
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
    precondition {
      condition     = !(var.vpc_connector_id != null && (var.vpc_network != null || var.vpc_subnetwork != null))
      error_message = "Cannot use both vpc_connector_id (legacy) and vpc_network/vpc_subnetwork (Direct VPC Egress). Choose one VPC connectivity method."
    }

    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
      template[0].labels,
    ]
  }
}
