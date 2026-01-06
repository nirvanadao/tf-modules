output "ip_address" {
  description = "The static IP address"
  value       = google_compute_global_address.ip.address
}

output "ip_name" {
  description = "The name of the static IP resource"
  value       = google_compute_global_address.ip.name
}

output "ssl_certificate_id" {
  description = "The ID of the SSL certificate"
  value       = google_compute_managed_ssl_certificate.cert.id
}

output "ssl_certificate_name" {
  description = "The name of the SSL certificate"
  value       = google_compute_managed_ssl_certificate.cert.name
}
