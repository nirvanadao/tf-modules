
# Get available zones in the region if not specified
data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
}

locals {
  # Use provided zones or all available zones in the region
  zones = var.distribution_zones != null ? var.distribution_zones : data.google_compute_zones.available.names

  # For regional MIGs: max_surge must be 0 or >= number of zones
  calculated_max_surge = var.max_surge_fixed > 0 ? max(var.max_surge_fixed, length(local.zones)) : 0
}

# ==============================================================================
# 1. HEALTH CHECKS & NETWORK
# ==============================================================================

resource "google_compute_health_check" "autohealing" {
  name                = "${var.name}-hc"
  project             = var.project_id
  check_interval_sec  = var.health_check_interval
  timeout_sec         = var.health_check_timeout
  healthy_threshold   = var.health_check_healthy_threshold
  unhealthy_threshold = var.health_check_unhealthy_threshold

  http_health_check {
    port         = var.health_check_port
    request_path = var.health_check_path
  }

  log_config {
    enable = true
  }
}

# CRITICAL: Allow Google Health Check probes to reach instances
# Without this, new instances will fail health checks and be recreated infinitely
resource "google_compute_firewall" "allow_health_check" {
  count   = var.create_health_check_firewall ? 1 : 0
  name    = "${var.name}-allow-hc"
  project = var.project_id
  network = var.network
  
  direction = "INGRESS"
  priority  = 1000
  
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = var.target_tags

  allow {
    protocol = "tcp"
    ports    = [var.health_check_port]
  }
}

# ==============================================================================
# 2. MANAGED INSTANCE GROUP
# ==============================================================================

resource "google_compute_region_instance_group_manager" "main" {
  name               = var.name
  project            = var.project_id
  base_instance_name = var.base_instance_name
  region             = var.region
  
  # If autoscaling is enabled, we generally ignore target_size in lifecycle
  target_size = var.autoscaling_enabled ? null : var.target_size

  version {
    instance_template = var.instance_template
  }

  distribution_policy_zones = local.zones

  dynamic "auto_healing_policies" {
    for_each = var.enable_auto_healing ? [1] : []
    content {
      health_check      = google_compute_health_check.autohealing.id
      initial_delay_sec = var.auto_healing_initial_delay
    }
  }

  update_policy {
    type                           = "PROACTIVE"
    minimal_action                 = "REPLACE"
    most_disruptive_allowed_action = "REPLACE"
    max_unavailable_fixed          = var.max_unavailable_fixed
    max_surge_fixed                = local.calculated_max_surge
    replacement_method             = "SUBSTITUTE" # Often faster than RECREATE
  }

  # Dynamic Named Ports (Improved from hardcoded "http")
  dynamic "named_port" {
    for_each = var.named_ports
    content {
      name = named_port.key
      port = named_port.value
    }
  }

  lifecycle {
    create_before_destroy = true
    # Ignore target_size changes if autoscaling is used to prevent fighting
    ignore_changes = [target_size] 
  }
}