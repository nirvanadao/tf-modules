# Pub/Sub Service Monitor

Monitoring alerts for Pub/Sub push subscription pipelines to Cloud Run services.

## Features

- **DLQ Breach Alert** (CRITICAL) - Messages landing in Dead Letter Queue
- **Push Failures Alert** (WARNING) - Non-200 responses from service
- **Staleness Alert** (WARNING) - Pipeline stalled (oldest message too old)
- **Delivery Latency Alert** (INFO) - P95 latency exceeds threshold

## Usage

### Basic Example

```hcl
module "monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pub-sub-service-monitor?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = "my-service"

  main_push_subscription_id = module.push_subscription.subscription_name
  dlq_pull_subscription_id  = module.push_subscription.dlq_monitoring_subscription_name

  critical_notification_channels = [google_monitoring_notification_channel.pagerduty.id]
  warning_notification_channels  = [google_monitoring_notification_channel.slack.id]
}
```

### With Custom Thresholds

```hcl
module "monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pub-sub-service-monitor?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = "high-volume-processor"

  main_push_subscription_id = module.push_subscription.subscription_name
  dlq_pull_subscription_id  = module.push_subscription.dlq_monitoring_subscription_name

  # Custom thresholds
  push_error_threshold         = 20   # 20 errors/min before alerting
  max_staleness_seconds        = 3600 # Alert if oldest message > 1 hour
  delivery_latency_threshold_ms = 5000 # Alert if P95 > 5 seconds

  critical_notification_channels = [google_monitoring_notification_channel.pagerduty.id]
  warning_notification_channels  = [google_monitoring_notification_channel.slack.id]
}
```

### Integration with pubsub-push-subscription Module

```hcl
module "push_subscription" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pubsub-push-subscription?ref=v1.0.0"

  project_id         = var.project_id
  region             = var.region
  name               = "my-service-sub"
  service_account_id = "my-service-invoker"

  topic_id               = module.topic.topic_id
  cloud_run_service_name = module.service.service_name
  cloud_run_service_url  = module.service.service_url
}

module "monitoring" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pub-sub-service-monitor?ref=v1.0.0"

  project_id   = var.project_id
  region       = var.region
  service_name = module.service.service_name

  main_push_subscription_id = module.push_subscription.subscription_name
  dlq_pull_subscription_id  = module.push_subscription.dlq_monitoring_subscription_name

  critical_notification_channels = var.critical_notification_channels
  warning_notification_channels  = var.warning_notification_channels
}
```

## Alert Details

### DLQ Breach (CRITICAL)

**When:** Any message lands in the Dead Letter Queue

**Why:** DLQ messages represent complete failures after all retry attempts.

**Check:**
- Cloud Run service logs for errors
- DLQ messages for patterns
- Recent deployments

### Push Failures (WARNING)

**When:** Non-200 responses exceed threshold

**Why:** Service is having trouble processing messages.

**Check:**
- Error rate by status code (500, 429, 503)
- Service resource utilization

### Pipeline Stalled (WARNING)

**When:** Oldest unacked message exceeds age threshold

**Why:** Consumer is down, crashing, or processing slower than ingestion.

**Check:**
- Service instance count
- Max instances limit
- Downstream dependencies

### Delivery Latency (INFO)

**When:** P95 delivery latency exceeds threshold

**Why:** Service is processing slowly (early warning).

**Check:**
- CPU/Memory utilization
- Database query performance
- External API response times

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_monitoring_alert_policy.delivery_latency](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.dlq_breach](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.push_failures](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.staleness](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dlq_pull_subscription_id"></a> [dlq\_pull\_subscription\_id](#input\_dlq\_pull\_subscription\_id) | The ID of the Dead Letter Queue subscription | `string` | n/a | yes |
| <a name="input_main_push_subscription_id"></a> [main\_push\_subscription\_id](#input\_main\_push\_subscription\_id) | The ID of the main push subscription | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | n/a | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | n/a | `string` | n/a | yes |
| <a name="input_service_name"></a> [service\_name](#input\_service\_name) | n/a | `string` | n/a | yes |
| <a name="input_ack_deadline_seconds"></a> [ack\_deadline\_seconds](#input\_ack\_deadline\_seconds) | Ack deadline (for documentation only) | `number` | `600` | no |
| <a name="input_critical_notification_channels"></a> [critical\_notification\_channels](#input\_critical\_notification\_channels) | Channels for CRITICAL alerts (PagerDuty) | `list(string)` | `[]` | no |
| <a name="input_delivery_latency_threshold_ms"></a> [delivery\_latency\_threshold\_ms](#input\_delivery\_latency\_threshold\_ms) | P95 delivery latency threshold in ms | `number` | `2000` | no |
| <a name="input_enable_dlq_alert"></a> [enable\_dlq\_alert](#input\_enable\_dlq\_alert) | Enable DLQ breach alert | `bool` | `true` | no |
| <a name="input_max_staleness_seconds"></a> [max\_staleness\_seconds](#input\_max\_staleness\_seconds) | Age of oldest unacked message to trigger warning | `number` | `1800` | no |
| <a name="input_push_error_threshold"></a> [push\_error\_threshold](#input\_push\_error\_threshold) | Non-success responses per minute to trigger warning | `number` | `10` | no |
| <a name="input_warning_notification_channels"></a> [warning\_notification\_channels](#input\_warning\_notification\_channels) | Channels for WARNING/INFO alerts (Slack) | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_delivery_latency_alert_id"></a> [delivery\_latency\_alert\_id](#output\_delivery\_latency\_alert\_id) | ID of the delivery latency alert policy |
| <a name="output_dlq_alert_id"></a> [dlq\_alert\_id](#output\_dlq\_alert\_id) | ID of the DLQ breach alert policy |
| <a name="output_push_failures_alert_id"></a> [push\_failures\_alert\_id](#output\_push\_failures\_alert\_id) | ID of the push failures alert policy |
| <a name="output_staleness_alert_id"></a> [staleness\_alert\_id](#output\_staleness\_alert\_id) | ID of the staleness alert policy |
<!-- END_TF_DOCS -->
