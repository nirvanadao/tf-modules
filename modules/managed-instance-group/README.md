# Managed Instance Group

Creates a regional Managed Instance Group (MIG) with autoscaling and auto-healing.

## Features

- **Regional Distribution** - Instances spread across zones for HA
- **Autoscaling** - CPU-based scaling with configurable thresholds
- **Auto-healing** - HTTP health checks with automatic instance replacement
- **Rolling Updates** - Configurable surge and unavailable limits
- **Health Check Firewall** - Optional firewall rule for GCP health checks

## Usage

### Basic Example

```hcl
module "mig" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/managed-instance-group?ref=v1.0.0"

  project_id        = var.project_id
  region            = var.region
  name              = "my-app"
  instance_template = google_compute_instance_template.app.self_link
  network           = var.network_name
}
```

### With Custom Scaling

```hcl
module "mig" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/managed-instance-group?ref=v1.0.0"

  project_id        = var.project_id
  region            = var.region
  name              = "web-servers"
  instance_template = google_compute_instance_template.web.self_link
  network           = var.network_name

  # Scaling
  min_replicas          = 2
  max_replicas          = 20
  cpu_utilization_target = 0.7
  cooldown_period       = 120

  # Gradual scale-in to prevent thundering herd
  scale_in_max_fixed_replicas = 2
  scale_in_time_window_sec    = 300
}
```

### With Custom Health Check

```hcl
module "mig" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/managed-instance-group?ref=v1.0.0"

  project_id        = var.project_id
  region            = var.region
  name              = "api-servers"
  instance_template = google_compute_instance_template.api.self_link
  network           = var.network_name

  # Health check
  health_check_path               = "/health"
  health_check_port               = 8080
  health_check_interval           = 10
  health_check_timeout            = 5
  health_check_healthy_threshold   = 2
  health_check_unhealthy_threshold = 3

  # Auto-healing
  enable_auto_healing       = true
  auto_healing_initial_delay = 300
}
```

### Fixed Size (No Autoscaling)

```hcl
module "mig" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/managed-instance-group?ref=v1.0.0"

  project_id        = var.project_id
  region            = var.region
  name              = "bastion"
  instance_template = google_compute_instance_template.bastion.self_link
  network           = var.network_name

  autoscaling_enabled = false
  target_size         = 1
}
```

### With Named Ports (for Load Balancer)

```hcl
module "mig" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/managed-instance-group?ref=v1.0.0"

  project_id        = var.project_id
  region            = var.region
  name              = "backend"
  instance_template = google_compute_instance_template.backend.self_link
  network           = var.network_name

  named_ports = {
    http  = 8080
    https = 8443
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.allow_health_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_firewall) | resource |
| [google_compute_health_check.autohealing](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_health_check) | resource |
| [google_compute_region_autoscaler.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_autoscaler) | resource |
| [google_compute_region_instance_group_manager.main](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_instance_group_manager) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_instance_template"></a> [instance\_template](#input\_instance\_template) | n/a | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | n/a | `string` | n/a | yes |
| <a name="input_network"></a> [network](#input\_network) | Network name for firewall rules | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_auto_healing_initial_delay"></a> [auto\_healing\_initial\_delay](#input\_auto\_healing\_initial\_delay) | n/a | `number` | `300` | no |
| <a name="input_autoscaling_enabled"></a> [autoscaling\_enabled](#input\_autoscaling\_enabled) | n/a | `bool` | `true` | no |
| <a name="input_base_instance_name"></a> [base\_instance\_name](#input\_base\_instance\_name) | --- Updates --- | `string` | `"app"` | no |
| <a name="input_cooldown_period"></a> [cooldown\_period](#input\_cooldown\_period) | n/a | `number` | `60` | no |
| <a name="input_cpu_utilization_target"></a> [cpu\_utilization\_target](#input\_cpu\_utilization\_target) | n/a | `number` | `0.6` | no |
| <a name="input_create_health_check_firewall"></a> [create\_health\_check\_firewall](#input\_create\_health\_check\_firewall) | --- Networking --- | `bool` | `true` | no |
| <a name="input_distribution_zones"></a> [distribution\_zones](#input\_distribution\_zones) | n/a | `list(string)` | `null` | no |
| <a name="input_enable_auto_healing"></a> [enable\_auto\_healing](#input\_enable\_auto\_healing) | --- Health Check --- | `bool` | `true` | no |
| <a name="input_health_check_healthy_threshold"></a> [health\_check\_healthy\_threshold](#input\_health\_check\_healthy\_threshold) | n/a | `number` | `2` | no |
| <a name="input_health_check_interval"></a> [health\_check\_interval](#input\_health\_check\_interval) | n/a | `number` | `10` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | n/a | `string` | `"/health"` | no |
| <a name="input_health_check_port"></a> [health\_check\_port](#input\_health\_check\_port) | n/a | `number` | `8080` | no |
| <a name="input_health_check_timeout"></a> [health\_check\_timeout](#input\_health\_check\_timeout) | n/a | `number` | `5` | no |
| <a name="input_health_check_unhealthy_threshold"></a> [health\_check\_unhealthy\_threshold](#input\_health\_check\_unhealthy\_threshold) | n/a | `number` | `3` | no |
| <a name="input_max_replicas"></a> [max\_replicas](#input\_max\_replicas) | n/a | `number` | `5` | no |
| <a name="input_max_surge_fixed"></a> [max\_surge\_fixed](#input\_max\_surge\_fixed) | n/a | `number` | `3` | no |
| <a name="input_max_unavailable_fixed"></a> [max\_unavailable\_fixed](#input\_max\_unavailable\_fixed) | n/a | `number` | `0` | no |
| <a name="input_min_replicas"></a> [min\_replicas](#input\_min\_replicas) | n/a | `number` | `1` | no |
| <a name="input_named_ports"></a> [named\_ports](#input\_named\_ports) | Map of named ports (name => port) | `map(number)` | <pre>{<br/>  "http": 8080<br/>}</pre> | no |
| <a name="input_scale_in_max_fixed_replicas"></a> [scale\_in\_max\_fixed\_replicas](#input\_scale\_in\_max\_fixed\_replicas) | Max number of instances to kill within the time window. Low numbers prevent thundering herds. | `number` | `1` | no |
| <a name="input_scale_in_time_window_sec"></a> [scale\_in\_time\_window\_sec](#input\_scale\_in\_time\_window\_sec) | The time window during which the max\_scaled\_in\_replicas limit applies. | `number` | `600` | no |
| <a name="input_target_size"></a> [target\_size](#input\_target\_size) | Fixed size if autoscaling disabled | `number` | `1` | no |
| <a name="input_target_tags"></a> [target\_tags](#input\_target\_tags) | Network tags to attach the health check firewall rule to | `list(string)` | <pre>[<br/>  "allow-health-check"<br/>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_distribution_zones"></a> [distribution\_zones](#output\_distribution\_zones) | The zones where instances are distributed |
| <a name="output_health_check_id"></a> [health\_check\_id](#output\_health\_check\_id) | The ID of the health check |
| <a name="output_health_check_name"></a> [health\_check\_name](#output\_health\_check\_name) | The name of the health check |
| <a name="output_health_check_self_link"></a> [health\_check\_self\_link](#output\_health\_check\_self\_link) | The self-link of the health check |
| <a name="output_mig_id"></a> [mig\_id](#output\_mig\_id) | The ID of the managed instance group |
| <a name="output_mig_instance_group"></a> [mig\_instance\_group](#output\_mig\_instance\_group) | The full URL of the instance group created by the manager |
| <a name="output_mig_name"></a> [mig\_name](#output\_mig\_name) | The name of the managed instance group |
| <a name="output_mig_self_link"></a> [mig\_self\_link](#output\_mig\_self\_link) | The self-link of the managed instance group |
| <a name="output_mig_status"></a> [mig\_status](#output\_mig\_status) | The status of the managed instance group |
| <a name="output_region"></a> [region](#output\_region) | The region where the MIG is deployed |
| <a name="output_target_size"></a> [target\_size](#output\_target\_size) | The target number of instances in the group |
<!-- END_TF_DOCS -->
