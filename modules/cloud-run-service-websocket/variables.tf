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

variable "image_url" {
  description = "Docker image URL (e.g., us-docker.pkg.dev/project/repo/image:tag)"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC Access Connector ID for connecting to VPC resources (Redis)"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables for the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "secret_environment_variables" {
  description = "Secret environment variables (name -> Secret Manager secret resource name)"
  type        = map(string)
  default     = {}
}

variable "domain" {
  description = "Domain name for the SSL certificate (e.g., ws.example.com)"
  type        = string
}

variable "service_account_roles" {
  description = "Additional IAM roles to grant to the service account (telemetry roles are always included)"
  type        = list(string)
  default     = []
}
