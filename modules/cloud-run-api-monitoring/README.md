# Cloud Run API Monitoring

Monitoring alerts for Cloud Run services based on latency and error rate, with two-tier alerting (Critical/Warning).

## Features

- **Latency Alerts** - P95 latency thresholds (Warning + Critical)
- **Error Rate Alerts** - 5xx error rate thresholds (Warning + Critical)
- **Two-Tier Notifications** - Critical (PagerDuty) vs Warning (Slack)
- **Configurable Thresholds** - Tune for your service's SLOs

## Usage

### Basic Example

```hcl
module "api_monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-api-monitoring?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = "my-api"

  critical_notification_channels = [google_monitoring_notification_channel.pagerduty.id]
  warning_notification_channels  = [google_monitoring_notification_channel.slack.id]
}
```

### With Custom Thresholds

```hcl
module "api_monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-api-monitoring?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = "checkout-api"

  # Latency thresholds
  latency_warning_ms  = 1000  # Warn at 1s P95
  latency_critical_ms = 3000  # Page at 3s P95

  # Error rate thresholds
  error_rate_warning  = 0.005  # Warn at 0.5% errors
  error_rate_critical = 0.02   # Page at 2% errors

  # How long before alerting
  alert_duration_seconds = 300  # 5 minutes

  critical_notification_channels = [google_monitoring_notification_channel.pagerduty.id]
  warning_notification_channels  = [google_monitoring_notification_channel.slack.id]
}
```

### With Cloud Run Service Module

```hcl
module "api" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-service?ref=v1.0.0"

  project_id       = var.project_id
  region           = var.region
  service_name     = "my-api"
  initial_image    = "us-docker.pkg.dev/my-project/repo/my-api:latest"
  vpc_connector_id = var.vpc_connector_id
}

module "api_monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-api-monitoring?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = module.api.service_name

  critical_notification_channels = var.critical_notification_channels
  warning_notification_channels  = var.warning_notification_channels
}
```

### Disable Specific Alerts

```hcl
module "api_monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-api-monitoring?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = "batch-processor"

  # Only alert on errors, not latency
  enable_latency_alerts = false
  enable_error_alerts   = true

  critical_notification_channels = [google_monitoring_notification_channel.pagerduty.id]
  warning_notification_channels  = [google_monitoring_notification_channel.slack.id]
}
```

## Alert Details

| Alert | Severity | Default Threshold | Condition |
|-------|----------|-------------------|-----------|
| Latency Warning | WARNING | P95 > 2000ms | 5 min sustained |
| Latency Critical | CRITICAL | P95 > 5000ms | 5 min sustained |
| Error Warning | WARNING | > 1% 5xx rate | 5 min sustained |
| Error Critical | CRITICAL | > 5% 5xx rate | 5 min sustained |

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_monitoring_alert_policy.errors_critical](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.errors_warning](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.latency_critical](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.latency_warning](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID where the Cloud Run service is deployed. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud Run service is deployed (e.g., 'us-central1'). | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The exact name of the Cloud Run service to monitor. | `string` | n/a | yes |
| <a name="input_alert_duration_seconds"></a> [alert\_duration\_seconds](#input\_alert\_duration\_seconds) | How long a condition must persist before alerting (prevents flapping). | `number` | `300` | no |
| <a name="input_critical_notification_channels"></a> [critical\_notification\_channels](#input\_critical\_notification\_channels) | Notification channels for CRITICAL alerts (e.g., PagerDuty). | `list(string)` | `[]` | no |
| <a name="input_enable_error_alerts"></a> [enable\_error\_alerts](#input\_enable\_error\_alerts) | Enable 5xx error rate monitoring alerts. | `bool` | `true` | no |
| <a name="input_enable_latency_alerts"></a> [enable\_latency\_alerts](#input\_enable\_latency\_alerts) | Enable latency monitoring alerts. | `bool` | `true` | no |
| <a name="input_error_rate_critical"></a> [error\_rate\_critical](#input\_error\_rate\_critical) | 5xx error rate threshold for CRITICAL alerts (0.05 = 5%). | `number` | `0.05` | no |
| <a name="input_error_rate_warning"></a> [error\_rate\_warning](#input\_error\_rate\_warning) | 5xx error rate threshold for WARNING alerts (0.01 = 1%). | `number` | `0.01` | no |
| <a name="input_latency_critical_ms"></a> [latency\_critical\_ms](#input\_latency\_critical\_ms) | P95 latency threshold in milliseconds for CRITICAL alerts. | `number` | `5000` | no |
| <a name="input_latency_warning_ms"></a> [latency\_warning\_ms](#input\_latency\_warning\_ms) | P95 latency threshold in milliseconds for WARNING alerts. | `number` | `2000` | no |
| <a name="input_warning_notification_channels"></a> [warning\_notification\_channels](#input\_warning\_notification\_channels) | Notification channels for WARNING alerts (e.g., Slack). | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_errors_critical_alert_id"></a> [errors\_critical\_alert\_id](#output\_errors\_critical\_alert\_id) | The ID of the critical error rate alert policy. |
| <a name="output_errors_warning_alert_id"></a> [errors\_warning\_alert\_id](#output\_errors\_warning\_alert\_id) | The ID of the warning error rate alert policy. |
| <a name="output_latency_critical_alert_id"></a> [latency\_critical\_alert\_id](#output\_latency\_critical\_alert\_id) | The ID of the critical latency alert policy. |
| <a name="output_latency_warning_alert_id"></a> [latency\_warning\_alert\_id](#output\_latency\_warning\_alert\_id) | The ID of the warning latency alert policy. |
<!-- END_TF_DOCS -->
