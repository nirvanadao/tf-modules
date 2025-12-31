# Cloud Run service that receives Pub/Sub push messages
module "cloud_run_service" {
  source = "../cloud-run-service"

  project_id   = var.project_id
  region       = var.region
  service_name = var.service_name

  initial_image    = var.initial_image
  vpc_connector_id = var.vpc_connector_id

  ingress               = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  allow_unauthenticated = false

  environment_variables        = var.environment_variables
  secret_environment_variables = var.secret_environment_variables
  service_account_roles        = var.service_account_roles

  cpu                     = var.cpu
  memory                  = var.memory
  min_instances           = var.min_instances
  max_instances           = var.max_instances
  timeout_seconds         = var.timeout_seconds
  max_request_concurrency = var.max_request_concurrency

  liveness_probe_path                  = var.liveness_probe_path
  liveness_probe_initial_delay_seconds = var.liveness_probe_initial_delay_seconds
  liveness_probe_period_seconds        = var.liveness_probe_period_seconds
  liveness_probe_timeout_seconds       = var.liveness_probe_timeout_seconds
  liveness_probe_failure_threshold     = var.liveness_probe_failure_threshold
}

# Pub/Sub push subscription that delivers messages to Cloud Run
module "pubsub_push_subscription" {
  source = "../pubsub-push-subscription"

  project_id = var.project_id
  region     = var.region

  name               = "${var.service_name}-push"
  service_account_id = "${var.service_name}-invoker"
  topic_id           = var.topic_id

  cloud_run_service_name = module.cloud_run_service.service_name
  cloud_run_service_url  = module.cloud_run_service.service_url
  push_endpoint_path     = var.push_endpoint_path

  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = var.message_retention_duration
  retry_minimum_backoff      = var.retry_minimum_backoff
  retry_maximum_backoff      = var.retry_maximum_backoff
  max_delivery_attempts      = var.max_delivery_attempts

  dlq_message_retention_duration = var.dlq_message_retention_duration

  labels = var.labels
}

# Optional: Pub/Sub monitoring alerts
module "pubsub_monitoring" {
  source = "../pub-sub-service-monitor"
  count  = var.enable_monitoring ? 1 : 0

  project_id   = var.project_id
  region       = var.region
  service_name = var.service_name

  main_push_subscription_id = module.pubsub_push_subscription.subscription_name
  dlq_pull_subscription_id  = module.pubsub_push_subscription.dlq_monitoring_subscription_name

  critical_notification_channels = var.critical_notification_channels
  warning_notification_channels  = var.warning_notification_channels

  enable_dlq_alert = var.enable_dlq_alert

  ack_deadline_seconds          = var.ack_deadline_seconds
  push_error_threshold          = var.push_error_threshold
  max_staleness_seconds         = var.max_staleness_seconds
  delivery_latency_threshold_ms = var.delivery_latency_threshold_ms
}

# Optional: Cloud Run service monitoring alerts (latency, error rate)
module "cloud_run_monitoring" {
  source = "../cloud-run-api-monitoring"
  count  = var.enable_monitoring ? 1 : 0

  project_id   = var.project_id
  region       = var.region
  service_name = var.service_name

  critical_notification_channels = var.critical_notification_channels
  warning_notification_channels  = var.warning_notification_channels

  enable_latency_alerts = var.enable_latency_alerts
  enable_error_alerts   = var.enable_error_alerts

  # Worker-appropriate defaults (higher than API defaults)
  latency_warning_ms     = var.latency_warning_ms
  latency_critical_ms    = var.latency_critical_ms
  error_rate_warning     = var.error_rate_warning
  error_rate_critical    = var.error_rate_critical
  alert_duration_seconds = var.alert_duration_seconds
}
