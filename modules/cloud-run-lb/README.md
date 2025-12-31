# Cloud Run Load Balancer

Creates a Global HTTP(S) Load Balancer for a Cloud Run service with managed SSL certificate.

## Features

- **Global Load Balancer** - Routes traffic to Cloud Run via serverless NEG
- **Managed SSL** - Auto-provisioned and renewed certificates
- **HTTP to HTTPS Redirect** - Automatic redirect for all HTTP traffic
- **Optional IAP** - Identity-Aware Proxy for authentication
- **Optional CDN** - Cloud CDN for caching

## Usage

### Basic Example

```hcl
module "lb" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-lb?ref=v1.0.0"

  project_id             = var.project_id
  region                 = var.region
  cloud_run_service_name = module.api.service_name
  domain_name            = "api.example.com"
}
```

### With CDN

```hcl
module "lb" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-lb?ref=v1.0.0"

  project_id             = var.project_id
  region                 = var.region
  cloud_run_service_name = module.api.service_name
  domain_name            = "api.example.com"

  enable_cdn = true
}
```

### With IAP Authentication

```hcl
module "lb" {
  source = "git::https://github.com/your-org/tf-modules.git//modules/cloud-run-lb?ref=v1.0.0"

  project_id             = var.project_id
  region                 = var.region
  cloud_run_service_name = module.internal_app.service_name
  domain_name            = "internal.example.com"

  enable_iap              = true
  iap_oauth2_client_id     = var.oauth_client_id
  iap_oauth2_client_secret = var.oauth_client_secret
}
```

## DNS Setup

After applying, create a DNS A record pointing to the load balancer IP:

```
api.example.com  A  <load_balancer_ip>
```

The managed SSL certificate will auto-provision once DNS propagates (can take up to 24 hours).

<!-- BEGIN_TF_DOCS -->
## Resources

| Name | Type |
|------|------|
| [google_compute_backend_service.backend](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_backend_service) | resource |
| [google_compute_global_address.lb_ip](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_address) | resource |
| [google_compute_global_forwarding_rule.http](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_global_forwarding_rule.https](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_global_forwarding_rule) | resource |
| [google_compute_managed_ssl_certificate.cert](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_managed_ssl_certificate) | resource |
| [google_compute_region_network_endpoint_group.serverless_neg](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_region_network_endpoint_group) | resource |
| [google_compute_target_http_proxy.http_proxy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_http_proxy) | resource |
| [google_compute_target_https_proxy.https_proxy](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_target_https_proxy) | resource |
| [google_compute_url_map.http_redirect](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |
| [google_compute_url_map.urlmap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_url_map) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_run_service_name"></a> [cloud\_run\_service\_name](#input\_cloud\_run\_service\_name) | Name of the Cloud Run service to load balance | `string` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Custom domain name for the load balancer (e.g., api.example.com) | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | GCP project ID | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Region where Cloud Run service is deployed | `string` | n/a | yes |
| <a name="input_enable_cdn"></a> [enable\_cdn](#input\_enable\_cdn) | Enable Cloud CDN for the backend | `bool` | `false` | no |
| <a name="input_enable_iap"></a> [enable\_iap](#input\_enable\_iap) | Enable Identity-Aware Proxy | `bool` | `false` | no |
| <a name="input_iap_oauth2_client_id"></a> [iap\_oauth2\_client\_id](#input\_iap\_oauth2\_client\_id) | OAuth2 client ID for IAP (required if enable\_iap is true) | `string` | `null` | no |
| <a name="input_iap_oauth2_client_secret"></a> [iap\_oauth2\_client\_secret](#input\_iap\_oauth2\_client\_secret) | OAuth2 client secret for IAP (required if enable\_iap is true) | `string` | `null` | no |
| <a name="input_ssl_certificate_name"></a> [ssl\_certificate\_name](#input\_ssl\_certificate\_name) | Name for the managed SSL certificate resource | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_backend_service_id"></a> [backend\_service\_id](#output\_backend\_service\_id) | ID of the backend service |
| <a name="output_domain_name"></a> [domain\_name](#output\_domain\_name) | Domain name configured for the load balancer |
| <a name="output_load_balancer_ip"></a> [load\_balancer\_ip](#output\_load\_balancer\_ip) | Static IP address of the load balancer |
| <a name="output_load_balancer_ip_name"></a> [load\_balancer\_ip\_name](#output\_load\_balancer\_ip\_name) | Name of the static IP resource |
| <a name="output_ssl_certificate_id"></a> [ssl\_certificate\_id](#output\_ssl\_certificate\_id) | ID of the managed SSL certificate |
| <a name="output_url_map_id"></a> [url\_map\_id](#output\_url\_map\_id) | ID of the URL map |
<!-- END_TF_DOCS -->
