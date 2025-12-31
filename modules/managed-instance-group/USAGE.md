Module Usage PatternsHere is how to use the single mig module for two very different use cases.Scenario 1: The "Singleton" (e.g., heavily stateful app, legacy app)You want exactly 1 VM. If it crashes, it should be replaced (Auto-healing). If you update the code, it should spin up a new one before killing the old one (Rolling Update) to ensure zero downtime.module "legacy_singleton" {
  source = "./modules/mig"

  name              = "legacy-app-v1"
  project_id        = var.project_id
  region            = "us-central1"
  network           = "default"
  instance_template = google_compute_region_instance_template.legacy.self_link

  # --- The "Singleton" Configuration ---
  autoscaling_enabled = false
  target_size         = 1

  # This ensures 0 downtime. It spins up new VMs across zones before killing the old one.
  # Note: Regional MIGs require surge >= number of zones (usually 3) if max_unavailable is 0.
  max_unavailable_fixed = 0 
  max_surge_fixed       = 3 
}
Scenario 2: The "WebSocket Fleet" (Autoscaling with Safety)You want a fleet that scales up on CPU/Connections but scales down very slowly to avoid severing connections for thousands of users at once.module "websocket_server" {
  source = "./modules/mig"

  name              = "ws-server-v1"
  project_id        = var.project_id
  region            = "us-central1"
  network           = "default"
  instance_template = google_compute_region_instance_template.ws.self_link

  # --- The "Fleet" Configuration ---
  autoscaling_enabled = true
  min_replicas        = 3
  max_replicas        = 50
  
  # Trigger scale UP when CPU hits 60%
  cpu_utilization_target = 0.6

  # --- WebSocket Safety Valve ---
  # "Only kill 1 instance every 10 minutes"
  # This gives clients time to reconnect gradually rather than all at once.
  scale_in_max_fixed_replicas = 1
  scale_in_time_window_sec    = 600
}
Why this worksThe mig module isolates the infrastructure logic (Health Checks, Firewall rules, Regional distribution quirks) from the business logic (how many copies do I need?).Creating a wrapper module would just force you to pass these variables through another layer of abstraction, which adds maintenance overhead with no real benefit.