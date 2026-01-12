output "ip_address" {
  description = "The static IP address"
  value       = var.existing_ip_address != null ? var.existing_ip_address : google_compute_global_address.ip[0].address
}

output "ip_name" {
  description = "The name of the static IP resource"
  value       = var.existing_ip_address != null ? null : google_compute_global_address.ip[0].name
}

output "ssl_certificate_id" {
  description = "The ID of the SSL certificate"
  value       = var.existing_ssl_certificate_id != null ? var.existing_ssl_certificate_id : google_compute_managed_ssl_certificate.cert[0].id
}

output "ssl_certificate_name" {
  description = "The name of the SSL certificate"
  value       = var.existing_ssl_certificate_id != null ? null : google_compute_managed_ssl_certificate.cert[0].name
}
