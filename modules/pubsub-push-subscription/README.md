# Pub/Sub Push Subscription

Creates a Pub/Sub push subscription to a Cloud Run service with Dead Letter Queue.

## Features

- **Push Subscription** - Delivers messages to Cloud Run endpoint
- **Dead Letter Queue** - Captures failed messages after max retries
- **Service Account** - Dedicated invoker SA with Cloud Run permissions
- **Retry Policy** - Configurable backoff for failed deliveries
- **DLQ Monitoring Subscription** - Pull subscription for inspecting DLQ

## Usage

### Basic Example

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
```

### With Custom Settings

```hcl
module "push_subscription" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/pubsub-push-subscription?ref=v1.0.0"

  project_id         = var.project_id
  region             = var.region
  name               = "high-volume-sub"
  service_account_id = "high-volume-invoker"

  topic_id               = module.topic.topic_id
  cloud_run_service_name = module.service.service_name
  cloud_run_service_url  = module.service.service_url
  push_endpoint_path     = "/webhooks/pubsub"

  # Longer ack deadline for slow processing
  ack_deadline_seconds = 120

  # More retry attempts before DLQ
  max_delivery_attempts = 10

  # Retry backoff
  retry_minimum_backoff = "30s"
  retry_maximum_backoff = "600s"

  labels = {
    service = "data-processor"
  }
}
```

### With Monitoring

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

## Architecture

```
Topic → Push Subscription → Cloud Run Service
              ↓ (after max_delivery_attempts)
         DLQ Topic → DLQ Monitoring Subscription
```

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service_iam_member.pubsub_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_project_iam_member.pubsub_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_pubsub_subscription.dlq_monitoring](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_subscription.push_subscription](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription) | resource |
| [google_pubsub_topic.dlq](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic) | resource |
| [google_pubsub_topic_iam_member.dlq_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_pubsub_topic_iam_member.dlq_subscriber](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_service_account.pubsub_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_run_service_name"></a> [cloud\_run\_service\_name](#input\_cloud\_run\_service\_name) | Name of the Cloud Run service to push messages to | `string` | n/a | yes |
| <a name="input_cloud_run_service_url"></a> [cloud\_run\_service\_url](#input\_cloud\_run\_service\_url) | URL of the Cloud Run service | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Base name for the subscription (resources will be named: {name}, {name}-dlq, {name}-dlq-monitoring) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region where Cloud Run service is deployed | `string` | n/a | yes |
| <a name="input_service_account_id"></a> [service\_account\_id](#input\_service\_account\_id) | Service account ID for Pub/Sub invoker (6-30 characters, lowercase letters, numbers, hyphens) | `string` | n/a | yes |
| <a name="input_topic_id"></a> [topic\_id](#input\_topic\_id) | ID of the Pub/Sub topic to subscribe to | `string` | n/a | yes |
| <a name="input_ack_deadline_seconds"></a> [ack\_deadline\_seconds](#input\_ack\_deadline\_seconds) | Ack deadline for the subscription in seconds | `number` | `60` | no |
| <a name="input_dlq_message_retention_duration"></a> [dlq\_message\_retention\_duration](#input\_dlq\_message\_retention\_duration) | How long to retain messages in the DLQ | `string` | `"604800s"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to resources | `map(string)` | `{}` | no |
| <a name="input_max_delivery_attempts"></a> [max\_delivery\_attempts](#input\_max\_delivery\_attempts) | Maximum delivery attempts before sending to DLQ | `number` | `5` | no |
| <a name="input_message_retention_duration"></a> [message\_retention\_duration](#input\_message\_retention\_duration) | How long to retain unacknowledged messages | `string` | `"604800s"` | no |
| <a name="input_push_endpoint_path"></a> [push\_endpoint\_path](#input\_push\_endpoint\_path) | HTTP path for the push endpoint on the Cloud Run service | `string` | `"/pubsub/push"` | no |
| <a name="input_retry_maximum_backoff"></a> [retry\_maximum\_backoff](#input\_retry\_maximum\_backoff) | Maximum backoff for retries | `string` | `"600s"` | no |
| <a name="input_retry_minimum_backoff"></a> [retry\_minimum\_backoff](#input\_retry\_minimum\_backoff) | Minimum backoff for retries | `string` | `"10s"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dlq_monitoring_subscription_id"></a> [dlq\_monitoring\_subscription\_id](#output\_dlq\_monitoring\_subscription\_id) | ID of the DLQ monitoring subscription |
| <a name="output_dlq_monitoring_subscription_name"></a> [dlq\_monitoring\_subscription\_name](#output\_dlq\_monitoring\_subscription\_name) | Name of the DLQ monitoring subscription |
| <a name="output_dlq_topic_id"></a> [dlq\_topic\_id](#output\_dlq\_topic\_id) | ID of the dead letter queue topic |
| <a name="output_dlq_topic_name"></a> [dlq\_topic\_name](#output\_dlq\_topic\_name) | Name of the dead letter queue topic |
| <a name="output_pubsub_invoker_email"></a> [pubsub\_invoker\_email](#output\_pubsub\_invoker\_email) | Email of the Pub/Sub invoker service account |
| <a name="output_pubsub_invoker_id"></a> [pubsub\_invoker\_id](#output\_pubsub\_invoker\_id) | ID of the Pub/Sub invoker service account |
| <a name="output_subscription_id"></a> [subscription\_id](#output\_subscription\_id) | ID of the Pub/Sub push subscription |
| <a name="output_subscription_name"></a> [subscription\_name](#output\_subscription\_name) | Name of the Pub/Sub push subscription |
<!-- END_TF_DOCS -->
