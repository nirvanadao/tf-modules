output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.websocket_srv.name
}

output "service_url" {
  description = "URL of the Cloud Run service"
  value       = google_cloud_run_v2_service.websocket_srv.uri
}

output "service_account_email" {
  description = "Email of the service account used by Cloud Run"
  value       = google_service_account.service.email
}

output "load_balancer_ip" {
  description = "Static IP address of the load balancer"
  value       = var.lb_ip_address
}

output "load_balancer_url" {
  description = "HTTPS URL for the WebSocket endpoint"
  value       = "https://${var.domain}"
}
