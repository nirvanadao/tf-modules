# Required variables
variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "name" {
  description = "Base name for resources (e.g., 'stream-sigs-mainnet')"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC Access Connector ID from foundation module"
  type        = string
}

# Docker images
variable "scheduler_image" {
  description = "Docker image URL for task-scheduler"
  type        = string
  default = "us-docker.pkg.dev/roughmagic-shared/infra/task-scheduler:latest"
}

variable "worker_image" {
  description = "Docker image URL for stream-sigs-to-pubsub worker"
  type        = string
  default = "us-docker.pkg.dev/roughmagic-shared/infra/stream-sigs-to-pubsub:latest"
}

# Pub/Sub configuration
variable "pubsub_topic_name" {
  description = "Name for the Pub/Sub topic"
  type        = string
}

# Solana configuration
variable "solana_account_address" {
  description = "Solana account address to stream signatures for"
  type        = string
}

variable "solana_rpc_urls" {
  description = "Comma-separated list of Solana RPC URLs"
  type        = string
}

variable "solana_chain_id" {
  description = "Solana chain ID (solana-mainnet-beta, solana-devnet, solana-testnet)"
  type        = string
  default     = "solana-mainnet-beta"
}

variable "solana_commitment" {
  description = "Solana commitment level"
  type        = string
  default     = "finalized"
}

# Redis configuration
variable "redis_url" {
  description = "Redis URL for deduplication cache"
  type        = string
}

# GCS checkpoint configuration
variable "gcs_checkpoint_bucket" {
  description = "GCS bucket for checkpoint storage"
  type        = string
}

variable "gcs_checkpoint_file_path" {
  description = "GCS file path for checkpoint"
  type        = string
}

variable "default_checkpoint_signature" {
  description = "Default checkpoint signature for bootstrapping"
  type        = string
}

variable "job_lock_ttl_seconds" {
  description = "TTL for job-level mutex lock in seconds (prevents overlapping workers)"
  type        = number
  default     = 15
}

# Scheduler configuration
variable "scheduler_cron_schedule" {
  description = "Cron schedule for scheduler job (e.g., '* * * * *' for every minute)"
  type        = string
}

variable "scheduler_time_zone" {
  description = "Time zone for scheduler cron schedule"
  type        = string
  default     = "UTC"
}

variable "scheduler_paused" {
  description = "Whether the scheduler is paused"
  type        = bool
  default     = false
}

variable "scheduler_interval_seconds" {
  description = "How often the scheduler runs (should match cron schedule)"
  type        = number
  default     = 60
}

variable "task_interval_seconds" {
  description = "Interval between worker tasks (e.g., 5 for every 5 seconds)"
  type        = number
  default     = 5
}

variable "task_start_offset_seconds" {
  description = "Offset for first task (0 = immediate)"
  type        = number
  default     = 0
}

variable "scheduler_cpu" {
  description = "CPU allocation for scheduler job"
  type        = string
  default     = "1"
}

variable "scheduler_memory" {
  description = "Memory allocation for scheduler job"
  type        = string
  default     = "512Mi"
}

variable "scheduler_timeout_seconds" {
  description = "Timeout for scheduler job execution"
  type        = number
  default     = 300
}

variable "scheduler_max_retries" {
  description = "Max retries for scheduler job"
  type        = number
  default     = 1
}

variable "scheduler_task_count" {
  description = "Number of parallel tasks for scheduler"
  type        = number
  default     = 1
}

# Worker configuration
variable "worker_cpu" {
  description = "CPU allocation for worker service"
  type        = string
  default     = "1"
}

variable "worker_memory" {
  description = "Memory allocation for worker service"
  type        = string
  default     = "512Mi"
}

variable "worker_min_instances" {
  description = "Minimum number of worker instances"
  type        = number
  default     = 0
}

variable "worker_max_instances" {
  description = "Maximum number of worker instances"
  type        = number
  default     = 10
}

variable "worker_timeout_seconds" {
  description = "Timeout for worker execution"
  type        = number
  default     = 300
}

variable "worker_environment_variables" {
  description = "Additional environment variables for worker"
  type        = map(string)
  default     = {}
}

variable "worker_secret_environment_variables" {
  description = "Secret environment variables for worker"
  type        = map(string)
  default     = {}
}

# Cloud Tasks Queue configuration
variable "queue_max_concurrent_dispatches" {
  description = "Maximum concurrent task dispatches"
  type        = number
  default     = 100
}

variable "queue_max_dispatches_per_second" {
  description = "Maximum task dispatches per second"
  type        = number
  default     = 10
}

variable "queue_max_attempts" {
  description = "Maximum task retry attempts"
  type        = number
  default     = 3
}

variable "queue_max_retry_duration_seconds" {
  description = "Maximum retry duration in seconds"
  type        = number
  default     = 3600
}

variable "queue_min_backoff_seconds" {
  description = "Minimum backoff between retries"
  type        = number
  default     = 1
}

variable "queue_max_backoff_seconds" {
  description = "Maximum backoff between retries"
  type        = number
  default     = 600
}

variable "queue_max_doublings" {
  description = "Maximum number of backoff doublings"
  type        = number
  default     = 5
}

# Labels
variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

# ==============================================================================
# Monitoring Configuration
# ==============================================================================

variable "critical_notification_channels" {
  description = "Notification channels for CRITICAL alerts (e.g., PagerDuty)"
  type        = list(string)
  default     = []
}

variable "warning_notification_channels" {
  description = "Notification channels for WARNING alerts (e.g., Slack)"
  type        = list(string)
  default     = []
}

# --- Alert Toggles ---

variable "enable_worker_failure_alert" {
  description = "Enable worker 5xx error alerts"
  type        = bool
  default     = true
}

variable "enable_heartbeat_alert" {
  description = "Enable pipeline heartbeat (no traffic) alerts"
  type        = bool
  default     = true
}

variable "enable_scheduler_failure_alert" {
  description = "Enable scheduler job failure alerts"
  type        = bool
  default     = true
}

variable "enable_queue_depth_alert" {
  description = "Enable queue backlog depth alerts"
  type        = bool
  default     = true
}

# --- Thresholds ---

variable "worker_error_threshold" {
  description = "Number of 5xx errors per minute to trigger warning"
  type        = number
  default     = 1
}

variable "worker_error_critical_threshold" {
  description = "Number of 5xx errors per minute to trigger critical"
  type        = number
  default     = 10
}

variable "heartbeat_missing_seconds" {
  description = "Seconds without traffic before alerting pipeline stalled"
  type        = number
  default     = 120
}

variable "queue_depth_warning_threshold" {
  description = "Queue depth to trigger warning alert"
  type        = number
  default     = 500
}

variable "queue_depth_critical_threshold" {
  description = "Queue depth to trigger critical alert"
  type        = number
  default     = 2000
}

variable "alert_duration_seconds" {
  description = "How long a condition must persist before alerting"
  type        = number
  default     = 60
}

