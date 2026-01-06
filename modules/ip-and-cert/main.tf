# Static IP - long-lived, never changes
resource "google_compute_global_address" "ip" {
  project = var.project_id
  name    = var.ip_name
}

# Managed SSL Certificate - long-lived
resource "google_compute_managed_ssl_certificate" "cert" {
  project = var.project_id
  name    = var.cert_name

  managed {
    domains = [var.domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}
