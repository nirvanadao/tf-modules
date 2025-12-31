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

variable "domain_name" {
  description = "Custom domain name for the load balancer (e.g., api.example.com)"
  type        = string
}

variable "ssl_certificate_name" {
  description = "Name for the managed SSL certificate resource"
  type        = string
  default     = null
}

variable "enable_cdn" {
  description = "Enable Cloud CDN for the backend"
  type        = bool
  default     = false
}

variable "enable_iap" {
  description = "Enable Identity-Aware Proxy"
  type        = bool
  default     = false
}

variable "iap_oauth2_client_id" {
  description = "OAuth2 client ID for IAP (required if enable_iap is true)"
  type        = string
  default     = null
}

variable "iap_oauth2_client_secret" {
  description = "OAuth2 client secret for IAP (required if enable_iap is true)"
  type        = string
  sensitive   = true
  default     = null
}
