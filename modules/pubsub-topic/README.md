# Pub/Sub Topic

Creates a Pub/Sub topic with optional monitoring subscription.

## Features

- **Pub/Sub Topic** - With configurable message retention
- **Monitoring Subscription** - Optional pull subscription for observability
- **Labels** - For resource organization

## Usage

### Basic Example

```hcl
module "topic" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pubsub-topic?ref=v1.0.0"

  project_id = var.project_id
  name       = "my-events"
}
```

### With Monitoring Subscription

```hcl
module "topic" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pubsub-topic?ref=v1.0.0"

  project_id = var.project_id
  name       = "order-events"

  enable_monitoring_subscription = true

  labels = {
    environment = "production"
    service     = "orders"
  }
}
```

### Without Monitoring

```hcl
module "topic" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pubsub-topic?ref=v1.0.0"

  project_id = var.project_id
  name       = "internal-events"

  enable_monitoring_subscription = false
}
```

### With Custom Retention

```hcl
module "topic" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pubsub-topic?ref=v1.0.0"

  project_id = var.project_id
  name       = "critical-events"

  # Retain messages for 7 days
  message_retention_duration = "604800s"

  enable_monitoring_subscription          = true
  monitoring_message_retention_duration   = "604800s"
  monitoring_retain_acked_messages        = true
}
```

## Architecture

```
Publisher → Topic → Monitoring Subscription (optional)
              ↓
         Consumer Subscriptions (created separately)
```

## Monitoring Subscription

The optional monitoring subscription allows you to:
- Inspect messages flowing through the topic
- Debug message formats
- Test consumer behavior

Pull messages from the monitoring subscription:

```bash
gcloud pubsub subscriptions pull my-events-monitoring \
  --limit=10 \
  --project=my-project
```

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_pubsub_subscription.monitoring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.topic](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | Base name for the Pub/Sub topic (resources will be named: {name}, {name}-monitoring) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_enable_monitoring_subscription"></a> [enable\_monitoring\_subscription](#input\_enable\_monitoring\_subscription) | Whether to create a monitoring subscription | `bool` | `true` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Additional labels to apply to resources | `map(string)` | `{}` | no |
| <a name="input_message_retention_duration"></a> [message\_retention\_duration](#input\_message\_retention\_duration) | How long to retain unacknowledged messages in the topic | `string` | `"86400s"` | no |
| <a name="input_monitoring_ack_deadline_seconds"></a> [monitoring\_ack\_deadline\_seconds](#input\_monitoring\_ack\_deadline\_seconds) | Acknowledgment deadline for monitoring subscription | `number` | `60` | no |
| <a name="input_monitoring_expiration_ttl"></a> [monitoring\_expiration\_ttl](#input\_monitoring\_expiration\_ttl) | Subscription expires if inactive for this duration (empty string = never) | `string` | `""` | no |
| <a name="input_monitoring_message_retention_duration"></a> [monitoring\_message\_retention\_duration](#input\_monitoring\_message\_retention\_duration) | Message retention for monitoring subscription | `string` | `"604800s"` | no |
| <a name="input_monitoring_retain_acked_messages"></a> [monitoring\_retain\_acked\_messages](#input\_monitoring\_retain\_acked\_messages) | Whether to retain acknowledged messages in monitoring subscription | `bool` | `false` | no |
| <a name="input_retry_maximum_backoff"></a> [retry\_maximum\_backoff](#input\_retry\_maximum\_backoff) | Maximum backoff duration for retries | `string` | `"600s"` | no |
| <a name="input_retry_minimum_backoff"></a> [retry\_minimum\_backoff](#input\_retry\_minimum\_backoff) | Minimum backoff duration for retries | `string` | `"10s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_monitoring_subscription_id"></a> [monitoring\_subscription\_id](#output\_monitoring\_subscription\_id) | ID of the monitoring subscription (empty if not enabled) |
| <a name="output_monitoring_subscription_name"></a> [monitoring\_subscription\_name](#output\_monitoring\_subscription\_name) | Name of the monitoring subscription (empty if not enabled) |
| <a name="output_topic_id"></a> [topic\_id](#output\_topic\_id) | ID of the Pub/Sub topic |
| <a name="output_topic_name"></a> [topic\_name](#output\_topic\_name) | Name of the Pub/Sub topic |
<!-- END_TF_DOCS -->
