# Reserve static global IP address for HTTP load balancer
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.cloud_run_service_name}-http-ip"
  project = var.project_id
}

# Serverless Network Endpoint Group (NEG) pointing to Cloud Run
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.cloud_run_service_name}-http-neg"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.cloud_run_service_name
  }
}

# Backend service linking to the serverless NEG
resource "google_compute_backend_service" "backend" {
  name                  = "${var.cloud_run_service_name}-http-backend"
  project               = var.project_id
  protocol              = "HTTP"
  timeout_sec           = var.timeout_sec
  enable_cdn            = var.enable_cdn
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }
}

# URL map to route traffic to backend
resource "google_compute_url_map" "urlmap" {
  name            = "${var.cloud_run_service_name}-http"
  project         = var.project_id
  default_service = google_compute_backend_service.backend.id
}

# HTTP proxy
resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.cloud_run_service_name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.urlmap.id
}

# Global forwarding rule for HTTP (port 80)
resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.cloud_run_service_name}-http-fwd"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  target                = google_compute_target_http_proxy.http_proxy.id
}
