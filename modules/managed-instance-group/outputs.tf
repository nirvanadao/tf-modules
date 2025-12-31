# Managed Instance Group Outputs

output "mig_id" {
  description = "The ID of the managed instance group"
  value       = google_compute_region_instance_group_manager.main.id
}

output "mig_name" {
  description = "The name of the managed instance group"
  value       = google_compute_region_instance_group_manager.main.name
}

output "mig_self_link" {
  description = "The self-link of the managed instance group"
  value       = google_compute_region_instance_group_manager.main.self_link
}

output "mig_instance_group" {
  description = "The full URL of the instance group created by the manager"
  value       = google_compute_region_instance_group_manager.main.instance_group
}

output "mig_status" {
  description = "The status of the managed instance group"
  value       = google_compute_region_instance_group_manager.main.status
}

output "health_check_id" {
  description = "The ID of the health check"
  value       = google_compute_health_check.autohealing.id
}

output "health_check_name" {
  description = "The name of the health check"
  value       = google_compute_health_check.autohealing.name
}

output "health_check_self_link" {
  description = "The self-link of the health check"
  value       = google_compute_health_check.autohealing.self_link
}

output "target_size" {
  description = "The target number of instances in the group"
  value       = google_compute_region_instance_group_manager.main.target_size
}

output "region" {
  description = "The region where the MIG is deployed"
  value       = google_compute_region_instance_group_manager.main.region
}

output "distribution_zones" {
  description = "The zones where instances are distributed"
  value       = google_compute_region_instance_group_manager.main.distribution_policy_zones
}
