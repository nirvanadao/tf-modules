variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the Cloud Run service"
  type        = string
}

variable "service_name" {
  description = "Name of the Cloud Run service"
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

variable "ingress" {
  description = "Ingress settings for Cloud Run (INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER)"
  type        = string
  default     = "INGRESS_TRAFFIC_ALL"

  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Ingress must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access to the Cloud Run service"
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Environment variables for the Cloud Run service"
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
  description = "CPU allocation for the Cloud Run service"
  type        = string
  default     = "1"
}

variable "memory" {
  description = "Memory allocation for the Cloud Run service"
  type        = string
  default     = "512Mi"
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "min_instances" {
  description = "Minimum number of instances"
  type        = number
  default     = 0
}

variable "timeout_seconds" {
  description = "Request timeout in seconds"
  type        = number
  default     = 300
}

variable "liveness_probe_path" {
  description = "HTTP path for liveness probe"
  type        = string
  default     = "/healthz"
}

variable "liveness_probe_initial_delay_seconds" {
  description = "Initial delay before liveness probe starts"
  type        = number
  default     = 0
}

variable "liveness_probe_period_seconds" {
  description = "How often to perform the liveness probe"
  type        = number
  default     = 10
}

variable "liveness_probe_timeout_seconds" {
  description = "Timeout for liveness probe"
  type        = number
  default     = 1
}

variable "liveness_probe_failure_threshold" {
  description = "Number of failures before marking container as unhealthy"
  type        = number
  default     = 3
}

variable "max_request_concurrency" {
  description = "Maximum number of concurrent requests per container instance"
  type        = number
  default     = 80
}
