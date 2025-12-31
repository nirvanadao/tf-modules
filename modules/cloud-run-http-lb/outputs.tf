output "load_balancer_ip" {
  description = "Static IP address of the HTTP load balancer"
  value       = google_compute_global_address.lb_ip.address
}

output "load_balancer_ip_name" {
  description = "Name of the static IP resource"
  value       = google_compute_global_address.lb_ip.name
}

output "backend_service_id" {
  description = "ID of the backend service"
  value       = google_compute_backend_service.backend.id
}

output "url_map_id" {
  description = "ID of the URL map"
  value       = google_compute_url_map.urlmap.id
}
