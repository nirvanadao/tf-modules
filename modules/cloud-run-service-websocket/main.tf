# ==============================================================================
# 1. SERVICE ACCOUNT
# ==============================================================================

resource "google_service_account" "service" {
  project      = var.project_id
  account_id   = var.service_name
  display_name = "Service account for ${var.service_name}"
}

# ==============================================================================
# 2. CLOUD RUN SERVICE (WebSocket Optimized)
# ==============================================================================

resource "google_cloud_run_v2_service" "websocket_srv" {
  project  = var.project_id
  name     = var.service_name
  location = var.region
  ingress  = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" # Only allow traffic via LB

  template {
    service_account = google_service_account.service.email

    scaling {
      min_instance_count = 1 # Keep at least one alive for subscribers
      max_instance_count = 100
    }

    # CRITICAL: Connect to the VPC to reach Redis
    vpc_access {
      connector = var.vpc_connector_id
      egress    = "PRIVATE_RANGES_ONLY" # Only route internal traffic (Redis) through VPC
    }

    # CRITICAL: Websocket Timeout (60 mins)
    timeout = "3600s"

    containers {
      image = var.image_url

      # CRITICAL: No CPU Throttling (Always on CPU)
      # Required for background Redis subscriptions to work reliably
      resources {
        cpu_idle = false
        limits = {
          cpu    = "1000m"
          memory = "512Mi"
        }
      }

      ports {
        container_port = 8080
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

# Grant Secret Manager access for each secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  for_each = var.secret_environment_variables

  project   = var.project_id
  secret_id = split("/", each.value)[3]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service.email}"
}

# Allow the Load Balancer to invoke this service
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = google_cloud_run_v2_service.websocket_srv.location
  name     = google_cloud_run_v2_service.websocket_srv.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ==============================================================================
# 3. GLOBAL LOAD BALANCER (HTTPS)
# ==============================================================================

# A. Static Global IP
resource "google_compute_global_address" "lb_ip" {
  project = var.project_id
  name    = "${var.service_name}-ip"
}

# B. Managed SSL Certificate
resource "google_compute_managed_ssl_certificate" "lb_cert" {
  project = var.project_id
  name    = "${var.service_name}-cert"

  managed {
    domains = [var.domain]
  }
}

# C. Serverless Network Endpoint Group (The bridge between LB and Cloud Run)
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  project               = var.project_id
  name                  = "${var.service_name}-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region

  cloud_run {
    service = google_cloud_run_v2_service.websocket_srv.name
  }
}

# D. Backend Service (The Logic)
resource "google_compute_backend_service" "ws_backend" {
  project     = var.project_id
  name        = "${var.service_name}-backend"
  protocol    = "HTTP" # LB talks HTTP to Cloud Run (Cloud Run handles upgrade)
  port_name   = "http"
  timeout_sec = 3600 # CRITICAL: Match Cloud Run timeout (60m)
  enable_cdn  = false

  # CRITICAL: Sticky sessions help WebSocket upgrades succeed consistently
  session_affinity   = "GENERATED_COOKIE"
  locality_lb_policy = "RING_HASH"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

# E. URL Map (Routing)
resource "google_compute_url_map" "default" {
  project         = var.project_id
  name            = "${var.service_name}-url-map"
  default_service = google_compute_backend_service.ws_backend.id
}

# F. HTTPS Proxy
resource "google_compute_target_https_proxy" "default" {
  project          = var.project_id
  name             = "${var.service_name}-https-proxy"
  url_map          = google_compute_url_map.default.id
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_cert.id]
}

# G. Forwarding Rule (The Entry Point)
resource "google_compute_global_forwarding_rule" "default" {
  project    = var.project_id
  name       = "${var.service_name}-forwarding-rule"
  target     = google_compute_target_https_proxy.default.id
  port_range = "443"
  ip_address = google_compute_global_address.lb_ip.address
}
