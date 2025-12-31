# ==============================================================================
# AUTOSCALER
# ==============================================================================
resource "google_compute_region_autoscaler" "main" {
  count = var.autoscaling_enabled ? 1 : 0

  name    = "${var.name}-autoscaler"
  project = var.project_id
  region  = var.region
  target  = google_compute_region_instance_group_manager.main.id

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    # CPU Utilization Target
    # For WebSockets, consider using custom metrics (active connections) if CPU is not representative
    cpu_utilization {
      target = var.cpu_utilization_target
    }

    # CRITICAL FOR WEBSOCKETS: Scale-In Control
    # Prevents "Thundering Herd" by limiting how many instances can be killed at once.
    # e.g., "Don't kill more than 1 instance every 10 minutes"
    scale_in_control {
      max_scaled_in_replicas {
        fixed = var.scale_in_max_fixed_replicas
        # You can also use 'percent' here, but 'fixed' is safer for smaller clusters
      }
      time_window_sec = var.scale_in_time_window_sec
    }
  }
}