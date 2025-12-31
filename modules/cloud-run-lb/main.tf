# Reserve static global IP address
resource "google_compute_global_address" "lb_ip" {
  name    = "${var.cloud_run_service_name}-ip"
  project = var.project_id
}

# Managed SSL certificate for the domain
resource "google_compute_managed_ssl_certificate" "cert" {
  name    = coalesce(var.ssl_certificate_name, "${var.cloud_run_service_name}-cert")
  project = var.project_id

  managed {
    domains = [var.domain_name]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Serverless Network Endpoint Group (NEG) pointing to Cloud Run
resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "${var.cloud_run_service_name}-neg"
  project               = var.project_id
  region                = var.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = var.cloud_run_service_name
  }
}

# Backend service linking to the serverless NEG
resource "google_compute_backend_service" "backend" {
  name                  = "${var.cloud_run_service_name}-backend"
  project               = var.project_id
  protocol              = "HTTP"
  timeout_sec           = 30
  enable_cdn            = var.enable_cdn
  load_balancing_scheme = "EXTERNAL_MANAGED"

  backend {
    group = google_compute_region_network_endpoint_group.serverless_neg.id
  }

  dynamic "iap" {
    for_each = var.enable_iap ? [1] : []
    content {
      enabled              = true
      oauth2_client_id     = var.iap_oauth2_client_id
      oauth2_client_secret = var.iap_oauth2_client_secret
    }
  }
}

# URL map to route traffic to backend
resource "google_compute_url_map" "urlmap" {
  name            = var.cloud_run_service_name
  project         = var.project_id
  default_service = google_compute_backend_service.backend.id
}

# HTTPS proxy to terminate SSL
resource "google_compute_target_https_proxy" "https_proxy" {
  name             = "${var.cloud_run_service_name}-https"
  project          = var.project_id
  url_map          = google_compute_url_map.urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.cert.id]
}

# Global forwarding rule for HTTPS (443)
resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.cloud_run_service_name}-https"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  ip_address            = google_compute_global_address.lb_ip.address
  target                = google_compute_target_https_proxy.https_proxy.id
}

# HTTP to HTTPS redirect
resource "google_compute_url_map" "http_redirect" {
  name    = "${var.cloud_run_service_name}-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "http_proxy" {
  name    = "${var.cloud_run_service_name}-http"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect.id
}

resource "google_compute_global_forwarding_rule" "http" {
  name                  = "${var.cloud_run_service_name}-http"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  ip_address            = google_compute_global_address.lb_ip.address
  target                = google_compute_target_http_proxy.http_proxy.id
}
