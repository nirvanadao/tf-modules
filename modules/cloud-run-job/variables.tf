variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the Cloud Run job"
  type        = string
}

variable "job_name" {
  description = "Name of the Cloud Run job"
  type        = string
}

variable "initial_image" {
  description = "Initial Docker image URL (e.g., us-docker.pkg.dev/project/repo/image:tag) (will be ignored by Terraform after initial deployment)"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC Access Connector ID for connecting to VPC resources"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Cloud Run job"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables (name -> Secret Manager resource path)"
  type        = map(string)
  default     = {}
}

variable "service_account_roles" {
  description = "List of IAM roles to grant to the service account"
  type        = list(string)
  default     = []
}

variable "cpu" {
  description = "CPU allocation for the Cloud Run job"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for the Cloud Run job"
  type        = string
  default     = "512Mi"
}

variable "max_retries" {
  description = "Maximum number of retries for failed job executions"
  type        = number
  default     = 3
}

variable "timeout_seconds" {
  description = "Task execution timeout in seconds"
  type        = number
  default     = 600
}

variable "task_count" {
  description = "Number of tasks to run in parallel"
  type        = number
  default     = 1
}

variable "cron_schedule" {
  description = "Cron schedule for the job (e.g., '0 0 * * *' for daily at midnight)"
  type        = string
}

variable "time_zone" {
  description = "Time zone for the cron schedule (e.g., 'America/Los_Angeles')"
  type        = string
  default     = "UTC"
}

variable "scheduler_paused" {
  description = "Whether the scheduler is paused"
  type        = bool
  default     = false
}
