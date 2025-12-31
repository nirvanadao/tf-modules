# Cloud Run Job with Scheduled Cron Module

This Terraform module creates a Google Cloud Run Job with scheduled cron execution using Cloud Scheduler. It includes dedicated service accounts for both the job execution and the scheduler.

## Features

- **Cloud Run Job**: Containerized job execution with configurable resources
- **Cloud Scheduler**: Automated job triggering via cron schedule
- **Service Accounts**: Separate service accounts for job and scheduler
- **Environment Variables**: Support for both regular and secret environment variables
- **VPC Integration**: Configurable VPC connector for private networking
- **IAM Management**: Automatic role assignments and secret access permissions

## Usage

```hcl
module "my_scheduled_job" {
  source = "./terraform/modules/cloud-run-job"

  project_id        = "my-project-id"
  region            = "us-central1"
  job_name          = "my-scheduled-job"
  initial_image     = "us-docker.pkg.dev/my-project/my-repo/my-image:latest"
  vpc_connector_id  = "projects/my-project/locations/us-central1/connectors/my-connector"

  # Cron schedule (daily at midnight UTC)
  cron_schedule     = "0 0 * * *"
  time_zone         = "UTC"

  # Resource allocation
  cpu               = "1"
  memory            = "512Mi"
  timeout_seconds   = 600

  # Environment variables
  environment_variables = {
    NODE_ENV = "production"
    LOG_LEVEL = "info"
  }

  # Secret environment variables
  secret_environment_variables = {
    DATABASE_URL = "projects/my-project/secrets/database-url"
    API_KEY      = "projects/my-project/secrets/api-key"
  }

  # Service account permissions
  service_account_roles = [
    "roles/cloudsql.client",
    "roles/storage.objectViewer"
  ]
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_id | GCP project ID | string | - | yes |
| region | GCP region for the Cloud Run job | string | - | yes |
| job_name | Name of the Cloud Run job | string | - | yes |
| initial_image | Initial Docker image URL | string | - | yes |
| vpc_connector_id | VPC Access Connector ID | string | - | yes |
| cron_schedule | Cron schedule for the job | string | - | yes |
| time_zone | Time zone for the cron schedule | string | "UTC" | no |
| environment_variables | Environment variables | map(string) | {} | no |
| secret_environment_variables | Secret environment variables | map(string) | {} | no |
| service_account_roles | IAM roles to grant to the service account | list(string) | [] | no |
| cpu | CPU allocation | string | "1" | no |
| memory | Memory allocation | string | "512Mi" | no |
| max_retries | Maximum retries for failed executions | number | 3 | no |
| timeout_seconds | Task execution timeout | number | 600 | no |
| task_count | Number of tasks to run in parallel | number | 1 | no |
| scheduler_paused | Whether the scheduler is paused | bool | false | no |

## Outputs

| Name | Description |
|------|-------------|
| job_name | Name of the Cloud Run job |
| job_id | ID of the Cloud Run job |
| scheduler_name | Name of the Cloud Scheduler job |
| scheduler_id | ID of the Cloud Scheduler job |
| job_service_account_email | Email of the job service account |
| job_service_account_id | ID of the job service account |
| scheduler_service_account_email | Email of the scheduler service account |
| scheduler_service_account_id | ID of the scheduler service account |

## Cron Schedule Examples

- `"0 0 * * *"` - Daily at midnight
- `"0 */6 * * *"` - Every 6 hours
- `"0 0 * * 0"` - Weekly on Sunday at midnight
- `"0 0 1 * *"` - Monthly on the 1st at midnight
- `"*/15 * * * *"` - Every 15 minutes

## Notes

- The module creates two service accounts:
  - One for the Cloud Run job execution
  - One for Cloud Scheduler to invoke the job
- Secret environment variables automatically grant `secretAccessor` role to the job service account
- The image is ignored after initial deployment (managed outside Terraform)
- The scheduler can be paused by setting `scheduler_paused = true`

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_cloud_run_v2_job.job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job) | resource |
| [google_cloud_run_v2_job_iam_member.scheduler_invoker](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_run_v2_job_iam_member) | resource |
| [google_cloud_scheduler_job.scheduler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/cloud_scheduler_job) | resource |
| [google_project_iam_member.job_account_roles](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_member) | resource |
| [google_secret_manager_secret_iam_member.secret_accessor](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret_iam_member) | resource |
| [google_service_account.job](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account.scheduler](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cron_schedule"></a> [cron\_schedule](#input\_cron\_schedule) | Cron schedule for the job (e.g., '0 0 * * *' for daily at midnight) | `string` | n/a | yes |
| <a name="input_initial_image"></a> [initial\_image](#input\_initial\_image) | Initial Docker image URL (e.g., us-docker.pkg.dev/project/repo/image:tag) (will be ignored by Terraform after initial deployment) | `string` | n/a | yes |
| <a name="input_job_name"></a> [job\_name](#input\_job\_name) | Name of the Cloud Run job | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | GCP region for the Cloud Run job | `string` | n/a | yes |
| <a name="input_vpc_connector_id"></a> [vpc\_connector\_id](#input\_vpc\_connector\_id) | VPC Access Connector ID for connecting to VPC resources | `string` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | CPU allocation for the Cloud Run job | `string` | `"1"` | no |
| <a name="input_environment_variables"></a> [environment\_variables](#input\_environment\_variables) | Environment variables for the Cloud Run job | `map(string)` | `{}` | no |
| <a name="input_max_retries"></a> [max\_retries](#input\_max\_retries) | Maximum number of retries for failed job executions | `number` | `3` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | Memory allocation for the Cloud Run job | `string` | `"512Mi"` | no |
| <a name="input_scheduler_paused"></a> [scheduler\_paused](#input\_scheduler\_paused) | Whether the scheduler is paused | `bool` | `false` | no |
| <a name="input_secret_environment_variables"></a> [secret\_environment\_variables](#input\_secret\_environment\_variables) | Secret environment variables (name -> Secret Manager resource path) | `map(string)` | `{}` | no |
| <a name="input_service_account_roles"></a> [service\_account\_roles](#input\_service\_account\_roles) | List of IAM roles to grant to the service account | `list(string)` | `[]` | no |
| <a name="input_task_count"></a> [task\_count](#input\_task\_count) | Number of tasks to run in parallel | `number` | `1` | no |
| <a name="input_time_zone"></a> [time\_zone](#input\_time\_zone) | Time zone for the cron schedule (e.g., 'America/Los\_Angeles') | `string` | `"UTC"` | no |
| <a name="input_timeout_seconds"></a> [timeout\_seconds](#input\_timeout\_seconds) | Task execution timeout in seconds | `number` | `600` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_job_id"></a> [job\_id](#output\_job\_id) | ID of the Cloud Run job |
| <a name="output_job_name"></a> [job\_name](#output\_job\_name) | Name of the Cloud Run job |
| <a name="output_job_service_account_email"></a> [job\_service\_account\_email](#output\_job\_service\_account\_email) | Email of the service account used by Cloud Run job |
| <a name="output_job_service_account_id"></a> [job\_service\_account\_id](#output\_job\_service\_account\_id) | ID of the job service account |
| <a name="output_scheduler_id"></a> [scheduler\_id](#output\_scheduler\_id) | ID of the Cloud Scheduler job |
| <a name="output_scheduler_name"></a> [scheduler\_name](#output\_scheduler\_name) | Name of the Cloud Scheduler job |
| <a name="output_scheduler_service_account_email"></a> [scheduler\_service\_account\_email](#output\_scheduler\_service\_account\_email) | Email of the scheduler service account |
| <a name="output_scheduler_service_account_id"></a> [scheduler\_service\_account\_id](#output\_scheduler\_service\_account\_id) | ID of the scheduler service account |
<!-- END_TF_DOCS -->
