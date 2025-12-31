# Cloud Run Service Module

Deploys a Cloud Run v2 service with a dedicated service account, VPC connectivity, and Secret Manager integration.

## Features

- **Dedicated Service Account**: Auto-created with configurable IAM roles
- **Secret Manager Integration**: Auto-grants access to referenced secrets
- **VPC Connector**: Private egress for accessing internal resources
- **CI/CD Friendly**: Image updates are ignored after initial deploy
- **Health Checks**: Configurable liveness probe

## Usage

### Basic Example

```hcl
module "api" {
  source = "./modules/cloud-run-service"

  project_id       = "my-project"
  region           = "us-central1"
  service_name     = "my-api"
  initial_image    = "us-docker.pkg.dev/my-project/repo/my-api:latest"
  vpc_connector_id = google_vpc_access_connector.connector.id

  allow_unauthenticated = true
}
```

### With Environment Variables and Secrets

```hcl
module "api" {
  source = "./modules/cloud-run-service"

  project_id       = "my-project"
  region           = "us-central1"
  service_name     = "my-api"
  initial_image    = "us-docker.pkg.dev/my-project/repo/my-api:latest"
  vpc_connector_id = google_vpc_access_connector.connector.id

  # Plain environment variables
  environment_variables = {
    LOG_LEVEL    = "info"
    API_BASE_URL = "https://api.example.com"
  }

  # Secrets from Secret Manager (auto-grants accessor role)
  secret_environment_variables = {
    DATABASE_URL = "projects/my-project/secrets/db-connection-string"
    API_KEY      = "projects/my-project/secrets/external-api-key"
  }

  # IAM roles for the service account
  service_account_roles = [
    "roles/cloudsql.client",
    "roles/pubsub.publisher",
  ]
}
```

### Production Configuration

```hcl
module "api" {
  source = "./modules/cloud-run-service"

  project_id       = "my-project"
  region           = "us-central1"
  service_name     = "checkout-api"
  initial_image    = "us-docker.pkg.dev/my-project/repo/checkout:v1.0.0"
  vpc_connector_id = google_vpc_access_connector.connector.id

  # Scaling
  min_instances = 2        # Always-on for low latency
  max_instances = 100

  # Resources
  cpu    = "2"
  memory = "1Gi"

  # Request handling
  timeout_seconds         = 60
  max_request_concurrency = 80

  # Health checks
  liveness_probe_path              = "/health"
  liveness_probe_initial_delay_seconds = 10
  liveness_probe_period_seconds    = 30
  liveness_probe_failure_threshold = 3

  # Security: internal load balancer only
  ingress               = "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  allow_unauthenticated = false
}
```

### With Monitoring

```hcl
module "api" {
  source = "./modules/cloud-run-service"

  project_id       = "my-project"
  region           = "us-central1"
  service_name     = "my-api"
  initial_image    = "us-docker.pkg.dev/my-project/repo/my-api:latest"
  vpc_connector_id = google_vpc_access_connector.connector.id

  max_instances = 50
}

module "api_monitoring" {
  source = "./modules/cloud-run-api-monitoring"

  project_id   = "my-project"
  region       = "us-central1"
  service_name = module.api.service_name

  max_instance_count = 50  # Match the service config

  critical_notification_channels = [google_monitoring_notification_channel.pagerduty.id]
  warning_notification_channels  = [google_monitoring_notification_channel.slack.id]
}
```

## Variables

### Required

| Name | Description |
|------|-------------|
| `project_id` | GCP project ID |
| `region` | GCP region (e.g., `us-central1`) |
| `service_name` | Name of the Cloud Run service |
| `initial_image` | Docker image URL for initial deployment |
| `vpc_connector_id` | VPC Access Connector ID |

### Optional

| Name | Default | Description |
|------|---------|-------------|
| `ingress` | `INGRESS_TRAFFIC_ALL` | Traffic source: `INGRESS_TRAFFIC_ALL`, `INGRESS_TRAFFIC_INTERNAL_ONLY`, `INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER` |
| `allow_unauthenticated` | `false` | Allow public access without authentication |
| `cpu` | `1` | CPU allocation (e.g., `1`, `2`, `4`) |
| `memory` | `512Mi` | Memory allocation (e.g., `512Mi`, `1Gi`, `2Gi`) |
| `min_instances` | `0` | Minimum instances (set > 0 to avoid cold starts) |
| `max_instances` | `10` | Maximum instances |
| `timeout_seconds` | `300` | Request timeout (max 3600) |
| `max_request_concurrency` | `80` | Max concurrent requests per instance |
| `environment_variables` | `{}` | Map of environment variables |
| `secret_environment_variables` | `{}` | Map of env var name to Secret Manager path |
| `service_account_roles` | `[]` | IAM roles to grant to the service account |
| `liveness_probe_path` | `/healthz` | HTTP path for liveness probe |
| `liveness_probe_initial_delay_seconds` | `0` | Delay before first probe |
| `liveness_probe_period_seconds` | `10` | Probe frequency |
| `liveness_probe_timeout_seconds` | `1` | Probe timeout |
| `liveness_probe_failure_threshold` | `3` | Failures before unhealthy |

## Outputs

| Name | Description |
|------|-------------|
| `service_name` | Name of the Cloud Run service |
| `service_id` | Full resource ID |
| `service_url` | HTTPS URL of the service |
| `service_account_email` | Service account email |
| `service_account_id` | Service account resource ID |

## Notes

### Image Management

The module ignores image changes after initial deployment:

```hcl
lifecycle {
  ignore_changes = [template[0].containers[0].image]
}
```

This allows CI/CD pipelines to deploy new images without Terraform reverting them. To update the image via Terraform, use `gcloud run deploy` or update the image and run `terraform apply -replace=module.api.google_cloud_run_v2_service.service`.

### VPC Connectivity

All egress traffic to private IP ranges (10.x.x.x, 172.16.x.x, 192.168.x.x) goes through the VPC connector. This enables access to:
- Cloud SQL with private IP
- Memorystore (Redis)
- Internal load balancers
- GKE services

### Secret Manager

When you add secrets via `secret_environment_variables`, the module automatically grants `roles/secretmanager.secretAccessor` to the service account. Use the full secret path:

```hcl
secret_environment_variables = {
  MY_SECRET = "projects/my-project/secrets/my-secret-name"
}
```

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service.service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service) | resource |
| [google_cloud_run_v2_service_iam_member.public_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_project_iam_member.service_account_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret_iam_member.secret_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.service](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_initial_image"></a> [initial\_image](#input\_initial\_image) | Initial Docker image URL (e.g., us-docker.pkg.dev/project/repo/image:tag) (will be ignored by Terraform after initial deployment) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the Cloud Run service | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | Name of the Cloud Run service | `string` | n/a | yes |
| <a name="input_vpc_connector_id"></a> [vpc\_connector\_id](#input\_vpc\_connector\_id) | VPC Access Connector ID for connecting to VPC resources | `string` | n/a | yes |
| <a name="input_allow_unauthenticated"></a> [allow\_unauthenticated](#input\_allow\_unauthenticated) | Allow unauthenticated access to the Cloud Run service | `bool` | `false` | no |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU allocation for the Cloud Run service | `string` | `"1"` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables for the Cloud Run service | `map(string)` | `{}` | no |
| <a name="input_ingress"></a> [ingress](#input\_ingress) | Ingress settings for Cloud Run (INGRESS\_TRAFFIC\_ALL, INGRESS\_TRAFFIC\_INTERNAL\_ONLY, INGRESS\_TRAFFIC\_INTERNAL\_LOAD\_BALANCER) | `string` | `"INGRESS_TRAFFIC_ALL"` | no |
| <a name="input_liveness_probe_failure_threshold"></a> [liveness\_probe\_failure\_threshold](#input\_liveness\_probe\_failure\_threshold) | Number of failures before marking container as unhealthy | `number` | `3` | no |
| <a name="input_liveness_probe_initial_delay_seconds"></a> [liveness\_probe\_initial\_delay\_seconds](#input\_liveness\_probe\_initial\_delay\_seconds) | Initial delay before liveness probe starts | `number` | `0` | no |
| <a name="input_liveness_probe_path"></a> [liveness\_probe\_path](#input\_liveness\_probe\_path) | HTTP path for liveness probe | `string` | `"/healthz"` | no |
| <a name="input_liveness_probe_period_seconds"></a> [liveness\_probe\_period\_seconds](#input\_liveness\_probe\_period\_seconds) | How often to perform the liveness probe | `number` | `10` | no |
| <a name="input_liveness_probe_timeout_seconds"></a> [liveness\_probe\_timeout\_seconds](#input\_liveness\_probe\_timeout\_seconds) | Timeout for liveness probe | `number` | `1` | no |
| <a name="input_max_instances"></a> [max\_instances](#input\_max\_instances) | Maximum number of instances | `number` | `10` | no |
| <a name="input_max_request_concurrency"></a> [max\_request\_concurrency](#input\_max\_request\_concurrency) | Maximum number of concurrent requests per container instance | `number` | `80` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory allocation for the Cloud Run service | `string` | `"512Mi"` | no |
| <a name="input_min_instances"></a> [min\_instances](#input\_min\_instances) | Minimum number of instances | `number` | `0` | no |
| <a name="input_secret_environment_variables"></a> [secret\_environment\_variables](#input\_secret\_environment\_variables) | Secret environment variables (name -> Secret Manager resource path) | `map(string)` | `{}` | no |
| <a name="input_service_account_roles"></a> [service\_account\_roles](#input\_service\_account\_roles) | List of IAM roles to grant to the service account | `list(string)` | `[]` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | Request timeout in seconds | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_service_account_email"></a> [service\_account\_email](#output\_service\_account\_email) | Email of the service account used by Cloud Run |
| <a name="output_service_account_id"></a> [service\_account\_id](#output\_service\_account\_id) | ID of the service account |
| <a name="output_service_id"></a> [service\_id](#output\_service\_id) | ID of the Cloud Run service |
| <a name="output_service_name"></a> [service\_name](#output\_service\_name) | Name of the Cloud Run service |
| <a name="output_service_url"></a> [service\_url](#output\_service\_url) | URL of the Cloud Run service |
<!-- END_TF_DOCS -->
