  module "http_lb" {
    source = "./modules/cloud-run-http-lb"

    project_id             = "my-project"
    region                 = "us-central1"
    cloud_run_service_name = "my-service"
  }
