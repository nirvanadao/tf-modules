# Static IP - long-lived, never changes (only created if no existing IP provided)
resource "google_compute_global_address" "ip" {
  count   = var.existing_ip_address == null ? 1 : 0
  project = var.project_id
  name    = var.ip_name
}

# Managed SSL Certificate - long-lived (only created if no existing cert provided)
resource "google_compute_managed_ssl_certificate" "cert" {
  count   = var.existing_ssl_certificate_id == null ? 1 : 0
  project = var.project_id
  name    = var.cert_name

  managed {
    domains = [var.domain]
  }

  lifecycle {
    create_before_destroy = true
  }
}
