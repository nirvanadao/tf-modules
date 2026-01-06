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
