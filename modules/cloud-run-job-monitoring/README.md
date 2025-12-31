# Cloud Run Job Monitoring

Simple failure monitoring for Cloud Run Jobs.

## Usage

### Basic (Alert on Any Failure)

```hcl
module "etl_job_monitoring" {
  source = "./modules/cloud-run-job-monitoring"

  project_id   = "my-project"
  job_name     = "nightly-etl"
  region       = "us-central1"

  notification_channels = [google_monitoring_notification_channel.slack.id]
}
```

### Reduce Noise for Flaky Jobs

```hcl
module "sync_job_monitoring" {
  source = "./modules/cloud-run-job-monitoring"

  project_id   = "my-project"
  job_name     = "data-sync"
  region       = "us-central1"

  # Don't alert on single failures
  alert_on_any_failure = false

  # Alert after 3 failures in an hour
  alert_on_consecutive_failures = true
  consecutive_failure_threshold = 3
  evaluation_window_minutes     = 60

  notification_channels = [google_monitoring_notification_channel.slack.id]
}
```

### With Cloud Run Job Module

```hcl
module "etl_job" {
  source = "./modules/cloud-run-job"

  project_id = "my-project"
  job_name   = "nightly-etl"
  region     = "us-central1"
  image      = "us-docker.pkg.dev/my-project/repo/etl:latest"
}

module "etl_monitoring" {
  source = "./modules/cloud-run-job-monitoring"

  project_id   = "my-project"
  job_name     = module.etl_job.job_name
  region       = "us-central1"

  notification_channels = [google_monitoring_notification_channel.pagerduty.id]
}
```

## Variables

| Name | Default | Description |
|------|---------|-------------|
| `project_id` | required | GCP project ID |
| `job_name` | required | Cloud Run Job name |
| `region` | required | GCP region |
| `notification_channels` | `[]` | Notification channel IDs |
| `alert_on_any_failure` | `true` | Alert on every failure |
| `alert_on_consecutive_failures` | `false` | Alert after N failures |
| `consecutive_failure_threshold` | `3` | Failures before alerting |
| `evaluation_window_minutes` | `60` | Window for counting failures |

## Outputs

| Name | Description |
|------|-------------|
| `failure_alert_id` | Alert policy ID for any-failure alerts |
| `consecutive_failures_alert_id` | Alert policy ID for consecutive failure alerts |

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_monitoring_alert_policy.job_consecutive_failures](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.job_failure](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_job_name"></a> [job\_name](#input\_job\_name) | The exact name of the Cloud Run Job to monitor. | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | The Google Cloud project ID. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The region where the Cloud Run Job is deployed (e.g., 'us-central1'). | `string` | n/a | yes |
| <a name="input_alert_on_any_failure"></a> [alert\_on\_any\_failure](#input\_alert\_on\_any\_failure) | Alert immediately on any job failure (recommended for critical jobs). | `bool` | `true` | no |
| <a name="input_alert_on_consecutive_failures"></a> [alert\_on\_consecutive\_failures](#input\_alert\_on\_consecutive\_failures) | Alert after multiple consecutive failures (reduces noise for flaky jobs). | `bool` | `false` | no |
| <a name="input_consecutive_failure_threshold"></a> [consecutive\_failure\_threshold](#input\_consecutive\_failure\_threshold) | Number of consecutive failures before alerting (when alert\_on\_consecutive\_failures is true). | `number` | `3` | no |
| <a name="input_evaluation_window_minutes"></a> [evaluation\_window\_minutes](#input\_evaluation\_window\_minutes) | Time window in minutes to evaluate for failures. | `number` | `60` | no |
| <a name="input_notification_channels"></a> [notification\_channels](#input\_notification\_channels) | Notification channel IDs for alerts. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_consecutive_failures_alert_id"></a> [consecutive\_failures\_alert\_id](#output\_consecutive\_failures\_alert\_id) | The ID of the consecutive failures alert policy. |
| <a name="output_failure_alert_id"></a> [failure\_alert\_id](#output\_failure\_alert\_id) | The ID of the job failure alert policy. |
<!-- END_TF_DOCS -->
