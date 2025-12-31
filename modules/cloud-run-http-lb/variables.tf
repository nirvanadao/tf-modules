variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Region where Cloud Run service is deployed"
  type        = string
}

variable "cloud_run_service_name" {
  description = "Name of the Cloud Run service to load balance"
  type        = string
}

variable "timeout_sec" {
  description = "Backend service timeout in seconds"
  type        = number
  default     = 30
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for the backend"
  type        = bool
  default     = false
}
