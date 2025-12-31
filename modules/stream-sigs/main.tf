terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  common_labels = merge(
    {
      managed_by = "terraform"
      component  = "stream-sigs"
    },
    var.labels
  )

}

# Pub/Sub Topic for signature messages
module "pubsub_topic" {
  source = "git::https://github.com/nirvanadao/tf.git//modules/pubsub-topic"

  project_id = var.project_id
  name       = var.pubsub_topic_name

  labels = local.common_labels
}

# GCS Bucket for checkpoint storage
resource "google_storage_bucket" "checkpoint_bucket" {
  project  = var.project_id
  name     = var.gcs_checkpoint_bucket
  location = var.region

  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  labels = local.common_labels
}

# Cloud Run Service - Processes tasks and publishes to Pub/Sub
module "worker_service" {
  source = "git::https://github.com/nirvanadao/tf.git//modules/cloud-run-service"

  project_id       = var.project_id
  region           = var.region
  service_name     = "${var.name}-worker"
  initial_image    = var.worker_image
  vpc_connector_id = var.vpc_connector_id

  # Resource allocation
  cpu             = var.worker_cpu
  memory          = var.worker_memory
  min_instances   = var.worker_min_instances
  max_instances   = var.worker_max_instances
  timeout_seconds = var.worker_timeout_seconds

  # No load balancer - invoked by Cloud Tasks
  ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"

  # Environment variables
  environment_variables = merge(
    {
      SOLANA_ACCOUNT_ADDRESS = var.solana_account_address
      SOLANA_RPC_URLS        = var.solana_rpc_urls
      SOLANA_CHAIN_ID        = var.solana_chain_id
      SOLANA_COMMITMENT      = var.solana_commitment
      GOOGLE_CLOUD_PROJECT_ID = var.project_id
      PUBSUB_TOPIC_NAME      = module.pubsub_topic.topic_name
      REDIS_URL              = var.redis_url
      GCS_CHECKPOINT_BUCKET  = var.gcs_checkpoint_bucket
      GCS_CHECKPOINT_FILE_PATH = var.gcs_checkpoint_file_path
      DEFAULT_CHECKPOINT_SIGNATURE = var.default_checkpoint_signature
      JOB_LOCK_TTL_SECONDS   = var.job_lock_ttl_seconds
    },
    var.worker_environment_variables
  )

  secret_environment_variables = var.worker_secret_environment_variables
}

# Cloud Tasks Queue
resource "google_cloud_tasks_queue" "queue" {
  project  = var.project_id
  location = var.region
  name     = "${var.name}-queue"

  rate_limits {
    max_concurrent_dispatches = var.queue_max_concurrent_dispatches
    max_dispatches_per_second = var.queue_max_dispatches_per_second
  }

  retry_config {
    max_attempts       = var.queue_max_attempts
    max_retry_duration = "${var.queue_max_retry_duration_seconds}s"
    min_backoff        = "${var.queue_min_backoff_seconds}s"
    max_backoff        = "${var.queue_max_backoff_seconds}s"
    max_doublings      = var.queue_max_doublings
  }
}

# Service account for Cloud Tasks to invoke worker
resource "google_service_account" "tasks_invoker" {
  project      = var.project_id
  account_id   = "${var.name}-invoker"
  display_name = "Cloud Tasks invoker for ${var.name}"
}

# Grant Cloud Tasks service account permission to invoke worker
resource "google_cloud_run_v2_service_iam_member" "tasks_invoker" {
  project  = var.project_id
  location = var.region
  name     = module.worker_service.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.tasks_invoker.email}"
}

# Cloud Run Job - Scheduler that fans out tasks
module "scheduler_job" {
  source = "git::https://github.com/nirvanadao/tf.git//modules/cloud-run-job"

  project_id       = var.project_id
  region           = var.region
  job_name         = "${var.name}-scheduler"
  initial_image    = var.scheduler_image
  vpc_connector_id = var.vpc_connector_id

  # Scheduler configuration
  cron_schedule    = var.scheduler_cron_schedule
  time_zone        = var.scheduler_time_zone
  scheduler_paused = var.scheduler_paused

  # Resource allocation
  cpu             = var.scheduler_cpu
  memory          = var.scheduler_memory
  timeout_seconds = var.scheduler_timeout_seconds
  max_retries     = var.scheduler_max_retries
  task_count      = var.scheduler_task_count

  # Environment variables
  environment_variables = {
    GCP_PROJECT_ID             = var.project_id
    GCP_LOCATION               = var.region
    GCP_QUEUE_NAME             = google_cloud_tasks_queue.queue.name
    GCP_TARGET_WORKER_URL      = module.worker_service.service_url
    GCP_OIDC_SERVICE_ACCOUNT   = google_service_account.tasks_invoker.email
    SCHEDULER_INTERVAL_SECONDS = var.scheduler_interval_seconds
    TASK_INTERVAL_SECONDS      = var.task_interval_seconds
    TASK_START_OFFSET_SECONDS  = var.task_start_offset_seconds
  }

  secret_environment_variables = {}
}

# Grant scheduler job permission to enqueue tasks
resource "google_cloud_tasks_queue_iam_member" "scheduler_enqueuer" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_tasks_queue.queue.name
  role     = "roles/cloudtasks.enqueuer"
  member   = "serviceAccount:${module.scheduler_job.job_service_account_email}"
}

# Grant scheduler job permission to act as tasks invoker
resource "google_service_account_iam_member" "scheduler_impersonation" {
  service_account_id = google_service_account.tasks_invoker.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${module.scheduler_job.job_service_account_email}"
}
