variable "project_id" { type = string }
variable "region" { type = string }
variable "name" { type = string }
variable "instance_template" { type = string }
variable "network" {
  description = "Network name for firewall rules"
  type        = string
}

# --- Sizing & Autoscaling ---
variable "target_size" {
  description = "Fixed size if autoscaling disabled"
  default     = 1
}
variable "autoscaling_enabled" { default = true }
variable "min_replicas" { default = 1 }
variable "max_replicas" { default = 5 }
variable "cooldown_period" { default = 60 }
variable "cpu_utilization_target" { default = 0.6 } # Scale at 60% CPU

# --- WebSocket Safety (Scale-In Controls) ---
variable "scale_in_max_fixed_replicas" {
  description = "Max number of instances to kill within the time window. Low numbers prevent thundering herds."
  default     = 1
}

variable "scale_in_time_window_sec" {
  description = "The time window during which the max_scaled_in_replicas limit applies."
  default     = 600 # 10 minutes
}

# --- Updates ---
variable "base_instance_name" { default = "app" }
variable "max_surge_fixed" { default = 3 }
variable "max_unavailable_fixed" { default = 0 }
variable "distribution_zones" {
  type    = list(string)
  default = null
}

# --- Health Check ---
variable "enable_auto_healing" { default = true }
variable "health_check_path" { default = "/health" }
variable "health_check_port" { default = 8080 }
variable "health_check_interval" { default = 10 }
variable "health_check_timeout" { default = 5 }
variable "health_check_healthy_threshold" { default = 2 }
variable "health_check_unhealthy_threshold" { default = 3 }
variable "auto_healing_initial_delay" { default = 300 }

# --- Networking ---
variable "create_health_check_firewall" { default = true }
variable "target_tags" {
  description = "Network tags to attach the health check firewall rule to"
  type        = list(string)
  default     = ["allow-health-check"]
}
variable "named_ports" {
  description = "Map of named ports (name => port)"
  type        = map(number)
  default     = { "http" = 8080 }
}