# Stream Sigs Module

This module sets up the complete signature streaming pipeline for Solana accounts.

## Architecture

```
┌─────────────────┐
│ Cloud Scheduler │ Triggers every minute
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│  Scheduler Job      │ Runs task-scheduler image
│  (Cloud Run Job)    │ Fans out N tasks to queue
└─────────┬───────────┘
          │
          ▼
┌───────────────────────┐
│  Cloud Tasks Queue    │ Buffers tasks
└───────────┬───────────┘
            │ Invokes for each task
            ▼
┌────────────────────────┐
│  Worker Service        │ Runs stream-sigs-to-pubsub
│  (Cloud Run Service)   │ Processes signatures
└──────┬─────────┬───────┘
       │         │ Publishes
       │         ▼
       │    ┌─────────────────────┐
       │    │  Pub/Sub Topic      │ Signature messages
       │    └─────────────────────┘
       │
       │ Reads/Writes
       ▼
┌─────────────────────┐
│  GCS Bucket         │ Checkpoint storage
└─────────────────────┘
```

## What It Creates

1. **Pub/Sub Topic** - For signature messages (with monitoring subscription)
2. **GCS Bucket** - For checkpoint storage with versioning enabled
3. **Worker Cloud Run Service** - Processes tasks, fetches signatures, publishes to Pub/Sub
4. **Cloud Tasks Queue** - Buffers work items between scheduler and worker
5. **Scheduler Cloud Run Job** - Fans out tasks to the queue on a schedule
6. **Service Accounts & IAM** - Proper permissions for all components:
   - Worker can publish to Pub/Sub topic
   - Worker has read/write access to checkpoint bucket
   - Tasks invoker can invoke worker service
   - Scheduler can enqueue tasks and impersonate invoker

## Example Usage

```hcl
module "stream_sigs_mainnet" {
  source = "../modules/stream-sigs"

  project_id       = "my-project"
  region           = "us-central1"
  name             = "stream-sigs-mainnet"
  vpc_connector_id = module.foundation.vpc_connector_id

  # Docker images
  scheduler_image = "us-docker.pkg.dev/my-project/repo/task-scheduler:latest"
  worker_image    = "us-docker.pkg.dev/my-project/repo/stream-sigs-to-pubsub:latest"

  # Pub/Sub
  pubsub_topic_name = "solana-signatures-mainnet"

  # Solana configuration
  solana_account_address = "YourProgramAddress..."
  solana_rpc_urls        = "https://api.mainnet-beta.solana.com,https://rpc.ankr.com/solana"
  solana_chain_id        = "solana-mainnet-beta"

  # Redis for deduplication
  redis_url = "redis://10.0.0.1:6379"

  # GCS checkpoint
  gcs_checkpoint_bucket    = "my-checkpoints"
  gcs_checkpoint_file_path = "stream-sigs/mainnet.json"
  default_checkpoint_signature = "5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d..."

  # Scheduler runs every minute, fans out tasks every 5 seconds
  scheduler_cron_schedule    = "* * * * *"
  scheduler_interval_seconds = 60
  task_interval_seconds      = 5

  labels = {
    environment = "production"
    chain       = "mainnet-beta"
  }
}
```

## Variables

### Required

- `project_id` - GCP project ID
- `region` - GCP region
- `name` - Base name for resources
- `vpc_connector_id` - VPC connector for private networking
- `scheduler_image` - Docker image for task-scheduler
- `worker_image` - Docker image for stream-sigs-to-pubsub
- `pubsub_topic_name` - Name for Pub/Sub topic
- `solana_account_address` - Account to stream signatures for
- `solana_rpc_urls` - Comma-separated RPC URLs
- `redis_url` - Redis connection string
- `gcs_checkpoint_bucket` - GCS bucket for checkpoints
- `gcs_checkpoint_file_path` - Path to checkpoint file
- `default_checkpoint_signature` - Bootstrap signature
- `scheduler_cron_schedule` - Cron schedule for scheduler

### Optional

See `variables.tf` for full list with defaults.

## Outputs

- `pubsub_topic_name` - Name of the Pub/Sub topic
- `checkpoint_bucket_name` - Name of the GCS checkpoint bucket
- `worker_service_url` - URL of the worker service
- `scheduler_job_name` - Name of the scheduler job
- `queue_name` - Name of the Cloud Tasks queue

## Notes

- The scheduler runs on a cron schedule (typically every minute)
- It fans out N tasks to the queue based on interval (e.g., 60s / 5s = 12 tasks)
- Each task invokes the worker service which fetches and publishes signatures
- Worker uses GCS checkpoints to track progress
- Redis is used for signature deduplication

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_service_iam_member.tasks_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_service_iam_member) | resource |
| [google_cloud_tasks_queue.queue](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_tasks_queue) | resource |
| [google_cloud_tasks_queue_iam_member.scheduler_enqueuer](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_tasks_queue_iam_member) | resource |
| [google_monitoring_alert_policy.queue_depth](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.scheduler_failures](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.worker_failures](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_monitoring_alert_policy.worker_heartbeat](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/monitoring_alert_policy) | resource |
| [google_pubsub_topic_iam_member.worker_publisher](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_topic_iam_member) | resource |
| [google_service_account.tasks_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.scheduler_impersonation](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket.checkpoint_bucket](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |
| [google_storage_bucket_iam_member.worker_checkpoint_access](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_default_checkpoint_signature"></a> [default\_checkpoint\_signature](#input\_default\_checkpoint\_signature) | Default checkpoint signature for bootstrapping | `string` | n/a | yes |
| <a name="input_gcs_checkpoint_bucket"></a> [gcs\_checkpoint\_bucket](#input\_gcs\_checkpoint\_bucket) | GCS bucket for checkpoint storage | `string` | n/a | yes |
| <a name="input_gcs_checkpoint_file_path"></a> [gcs\_checkpoint\_file\_path](#input\_gcs\_checkpoint\_file\_path) | GCS file path for checkpoint | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Base name for resources (e.g., 'stream-sigs-mainnet') | `string` | n/a | yes |
| <a name="input_notification_channels"></a> [notification\_channels](#input\_notification\_channels) | List of Notification Channel IDs | `list(string)` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_pubsub_topic_name"></a> [pubsub\_topic\_name](#input\_pubsub\_topic\_name) | Name for the Pub/Sub topic | `string` | n/a | yes |
| <a name="input_redis_url"></a> [redis\_url](#input\_redis\_url) | Redis URL for deduplication cache | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region | `string` | n/a | yes |
| <a name="input_scheduler_cron_schedule"></a> [scheduler\_cron\_schedule](#input\_scheduler\_cron\_schedule) | Cron schedule for scheduler job (e.g., '* * * * *' for every minute) | `string` | n/a | yes |
| <a name="input_solana_account_address"></a> [solana\_account\_address](#input\_solana\_account\_address) | Solana account address to stream signatures for | `string` | n/a | yes |
| <a name="input_solana_rpc_urls"></a> [solana\_rpc\_urls](#input\_solana\_rpc\_urls) | Comma-separated list of Solana RPC URLs | `string` | n/a | yes |
| <a name="input_vpc_connector_id"></a> [vpc\_connector\_id](#input\_vpc\_connector\_id) | VPC Access Connector ID from foundation module | `string` | n/a | yes |
| <a name="input_job_lock_ttl_seconds"></a> [job\_lock\_ttl\_seconds](#input\_job\_lock\_ttl\_seconds) | TTL for job-level mutex lock in seconds (prevents overlapping workers) | `number` | `15` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Labels to apply to resources | `map(string)` | `{}` | no |
| <a name="input_queue_max_attempts"></a> [queue\_max\_attempts](#input\_queue\_max\_attempts) | Maximum task retry attempts | `number` | `3` | no |
| <a name="input_queue_max_backoff_seconds"></a> [queue\_max\_backoff\_seconds](#input\_queue\_max\_backoff\_seconds) | Maximum backoff between retries | `number` | `600` | no |
| <a name="input_queue_max_concurrent_dispatches"></a> [queue\_max\_concurrent\_dispatches](#input\_queue\_max\_concurrent\_dispatches) | Maximum concurrent task dispatches | `number` | `100` | no |
| <a name="input_queue_max_dispatches_per_second"></a> [queue\_max\_dispatches\_per\_second](#input\_queue\_max\_dispatches\_per\_second) | Maximum task dispatches per second | `number` | `10` | no |
| <a name="input_queue_max_doublings"></a> [queue\_max\_doublings](#input\_queue\_max\_doublings) | Maximum number of backoff doublings | `number` | `5` | no |
| <a name="input_queue_max_retry_duration_seconds"></a> [queue\_max\_retry\_duration\_seconds](#input\_queue\_max\_retry\_duration\_seconds) | Maximum retry duration in seconds | `number` | `3600` | no |
| <a name="input_queue_min_backoff_seconds"></a> [queue\_min\_backoff\_seconds](#input\_queue\_min\_backoff\_seconds) | Minimum backoff between retries | `number` | `1` | no |
| <a name="input_scheduler_cpu"></a> [scheduler\_cpu](#input\_scheduler\_cpu) | CPU allocation for scheduler job | `string` | `"1"` | no |
| <a name="input_scheduler_image"></a> [scheduler\_image](#input\_scheduler\_image) | Docker image URL for task-scheduler | `string` | `"us-docker.pkg.dev/roughmagic-shared/infra/task-scheduler:latest"` | no |
| <a name="input_scheduler_interval_seconds"></a> [scheduler\_interval\_seconds](#input\_scheduler\_interval\_seconds) | How often the scheduler runs (should match cron schedule) | `number` | `60` | no |
| <a name="input_scheduler_max_retries"></a> [scheduler\_max\_retries](#input\_scheduler\_max\_retries) | Max retries for scheduler job | `number` | `1` | no |
| <a name="input_scheduler_memory"></a> [scheduler\_memory](#input\_scheduler\_memory) | Memory allocation for scheduler job | `string` | `"512Mi"` | no |
| <a name="input_scheduler_paused"></a> [scheduler\_paused](#input\_scheduler\_paused) | Whether the scheduler is paused | `bool` | `false` | no |
| <a name="input_scheduler_task_count"></a> [scheduler\_task\_count](#input\_scheduler\_task\_count) | Number of parallel tasks for scheduler | `number` | `1` | no |
| <a name="input_scheduler_time_zone"></a> [scheduler\_time\_zone](#input\_scheduler\_time\_zone) | Time zone for scheduler cron schedule | `string` | `"UTC"` | no |
| <a name="input_scheduler_timeout_seconds"></a> [scheduler\_timeout\_seconds](#input\_scheduler\_timeout\_seconds) | Timeout for scheduler job execution | `number` | `300` | no |
| <a name="input_solana_chain_id"></a> [solana\_chain\_id](#input\_solana\_chain\_id) | Solana chain ID (solana-mainnet-beta, solana-devnet, solana-testnet) | `string` | `"solana-mainnet-beta"` | no |
| <a name="input_solana_commitment"></a> [solana\_commitment](#input\_solana\_commitment) | Solana commitment level | `string` | `"finalized"` | no |
| <a name="input_task_interval_seconds"></a> [task\_interval\_seconds](#input\_task\_interval\_seconds) | Interval between worker tasks (e.g., 5 for every 5 seconds) | `number` | `5` | no |
| <a name="input_task_start_offset_seconds"></a> [task\_start\_offset\_seconds](#input\_task\_start\_offset\_seconds) | Offset for first task (0 = immediate) | `number` | `0` | no |
| <a name="input_worker_cpu"></a> [worker\_cpu](#input\_worker\_cpu) | CPU allocation for worker service | `string` | `"1"` | no |
| <a name="input_worker_environment_variables"></a> [worker\_environment\_variables](#input\_worker\_environment\_variables) | Additional environment variables for worker | `map(string)` | `{}` | no |
| <a name="input_worker_image"></a> [worker\_image](#input\_worker\_image) | Docker image URL for stream-sigs-to-pubsub worker | `string` | `"us-docker.pkg.dev/roughmagic-shared/infra/stream-sigs-to-pubsub:latest"` | no |
| <a name="input_worker_max_instances"></a> [worker\_max\_instances](#input\_worker\_max\_instances) | Maximum number of worker instances | `number` | `10` | no |
| <a name="input_worker_memory"></a> [worker\_memory](#input\_worker\_memory) | Memory allocation for worker service | `string` | `"512Mi"` | no |
| <a name="input_worker_min_instances"></a> [worker\_min\_instances](#input\_worker\_min\_instances) | Minimum number of worker instances | `number` | `0` | no |
| <a name="input_worker_secret_environment_variables"></a> [worker\_secret\_environment\_variables](#input\_worker\_secret\_environment\_variables) | Secret environment variables for worker | `map(string)` | `{}` | no |
| <a name="input_worker_timeout_seconds"></a> [worker\_timeout\_seconds](#input\_worker\_timeout\_seconds) | Timeout for worker execution | `number` | `300` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_checkpoint_bucket_name"></a> [checkpoint\_bucket\_name](#output\_checkpoint\_bucket\_name) | Name of the GCS checkpoint bucket |
| <a name="output_checkpoint_bucket_url"></a> [checkpoint\_bucket\_url](#output\_checkpoint\_bucket\_url) | URL of the GCS checkpoint bucket |
| <a name="output_pubsub_monitoring_subscription_name"></a> [pubsub\_monitoring\_subscription\_name](#output\_pubsub\_monitoring\_subscription\_name) | Name of the monitoring subscription |
| <a name="output_pubsub_topic_id"></a> [pubsub\_topic\_id](#output\_pubsub\_topic\_id) | ID of the Pub/Sub topic |
| <a name="output_pubsub_topic_name"></a> [pubsub\_topic\_name](#output\_pubsub\_topic\_name) | Name of the Pub/Sub topic |
| <a name="output_queue_id"></a> [queue\_id](#output\_queue\_id) | ID of the Cloud Tasks queue |
| <a name="output_queue_name"></a> [queue\_name](#output\_queue\_name) | Name of the Cloud Tasks queue |
| <a name="output_scheduler_job_id"></a> [scheduler\_job\_id](#output\_scheduler\_job\_id) | ID of the scheduler Cloud Run job |
| <a name="output_scheduler_job_name"></a> [scheduler\_job\_name](#output\_scheduler\_job\_name) | Name of the scheduler Cloud Run job |
| <a name="output_scheduler_name"></a> [scheduler\_name](#output\_scheduler\_name) | Name of the Cloud Scheduler job |
| <a name="output_scheduler_service_account_email"></a> [scheduler\_service\_account\_email](#output\_scheduler\_service\_account\_email) | Email of the scheduler job service account |
| <a name="output_tasks_invoker_email"></a> [tasks\_invoker\_email](#output\_tasks\_invoker\_email) | Email of the Cloud Tasks invoker service account |
| <a name="output_tasks_invoker_id"></a> [tasks\_invoker\_id](#output\_tasks\_invoker\_id) | ID of the Cloud Tasks invoker service account |
| <a name="output_worker_service_account_email"></a> [worker\_service\_account\_email](#output\_worker\_service\_account\_email) | Email of the worker service account |
| <a name="output_worker_service_name"></a> [worker\_service\_name](#output\_worker\_service\_name) | Name of the worker Cloud Run service |
| <a name="output_worker_service_url"></a> [worker\_service\_url](#output\_worker\_service\_url) | URL of the worker Cloud Run service |
<!-- END_TF_DOCS -->
