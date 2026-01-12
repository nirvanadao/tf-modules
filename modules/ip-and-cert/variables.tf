variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "ip_name" {
  description = "Name for the static IP resource"
  type        = string
}

variable "cert_name" {
  description = "Name for the SSL certificate resource"
  type        = string
}

variable "domain" {
  description = "Domain for SSL certificate"
  type        = string
}

variable "existing_ip_address" {
  description = "Existing static IP address. If provided, skip IP creation."
  type        = string
  default     = null
}

variable "existing_ssl_certificate_id" {
  description = "Existing SSL certificate ID. If provided, skip certificate creation."
  type        = string
  default     = null
}
