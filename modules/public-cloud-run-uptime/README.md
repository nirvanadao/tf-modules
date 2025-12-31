# Public Cloud Run Uptime Check

Global uptime monitoring for public Cloud Run services. Checks availability from USA, Europe, and Asia Pacific regions.

## Features

- **Global Health Checks**: Verifies service is reachable from 3 geographic regions
- **Content Matching**: Optional response body verification
- **False Positive Reduction**: Configurable failure threshold (default: 2+ regions must fail)

## Usage

```hcl
module "api_uptime" {
  source = "./modules/public-cloud-run-uptime"

  project_id   = "my-project"
  service_name = "my-api"
  service_url  = module.api.service_url  # or "https://api.example.com"

  health_check_path = "/health"

  critical_notification_channels = [
    google_monitoring_notification_channel.pagerduty.id
  ]
}
```

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_monitoring_alert_policy.uptime_failure](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_uptime_check_config.https_check](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_uptime_check_config) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | The name of the Cloud Run service (used for display names). | `string` | n/a | yes |
| <a name="input_service_url"></a> [service\_url](#input\_service\_url) | The public HTTPS URL of the Cloud Run service to monitor. | `string` | n/a | yes |
| <a name="input_check_period_seconds"></a> [check\_period\_seconds](#input\_check\_period\_seconds) | How often to run the uptime check (60, 300, 600, or 900 seconds). | `number` | `60` | no |
| <a name="input_content_match_string"></a> [content\_match\_string](#input\_content\_match\_string) | Optional string that must appear in the response body. Leave empty to skip content matching. | `string` | `""` | no |
| <a name="input_critical_notification_channels"></a> [critical\_notification\_channels](#input\_critical\_notification\_channels) | Notification channel IDs for critical alerts (uptime failures). | `list(string)` | `[]` | no |
| <a name="input_enable_uptime_check"></a> [enable\_uptime\_check](#input\_enable\_uptime\_check) | Enable the uptime check. Set to false to disable without removing. | `bool` | `true` | no |
| <a name="input_failure_threshold_regions"></a> [failure\_threshold\_regions](#input\_failure\_threshold\_regions) | Number of regions that must fail before alerting (1-3). Higher = fewer false positives. | `number` | `2` | no |
| <a name="input_health_check_path"></a> [health\_check\_path](#input\_health\_check\_path) | The HTTP path to check (e.g., '/' or '/health'). | `string` | `"/"` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | Timeout for the uptime check request. | `number` | `10` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_uptime_check_id"></a> [uptime\_check\_id](#output\_uptime\_check\_id) | The ID of the uptime check. |
| <a name="output_uptime_check_name"></a> [uptime\_check\_name](#output\_uptime\_check\_name) | The full resource name of the uptime check. |
| <a name="output_uptime_failure_alert_id"></a> [uptime\_failure\_alert\_id](#output\_uptime\_failure\_alert\_id) | The ID of the uptime failure alert policy. |
<!-- END_TF_DOCS -->
