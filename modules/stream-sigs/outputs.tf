# Pub/Sub outputs
output "pubsub_topic_name" {
  description = "Name of the Pub/Sub topic"
  value       = module.pubsub_topic.topic_name
}

output "pubsub_topic_id" {
  description = "ID of the Pub/Sub topic"
  value       = module.pubsub_topic.topic_id
}

output "pubsub_monitoring_subscription_name" {
  description = "Name of the monitoring subscription"
  value       = module.pubsub_topic.monitoring_subscription_name
}

# Worker service outputs
output "worker_service_name" {
  description = "Name of the worker Cloud Run service"
  value       = module.worker_service.service_name
}

output "worker_service_url" {
  description = "URL of the worker Cloud Run service"
  value       = module.worker_service.service_url
}

output "worker_service_account_email" {
  description = "Email of the worker service account"
  value       = module.worker_service.service_account_email
}

# Scheduler job outputs
output "scheduler_job_name" {
  description = "Name of the scheduler Cloud Run job"
  value       = module.scheduler_job.job_name
}

output "scheduler_job_id" {
  description = "ID of the scheduler Cloud Run job"
  value       = module.scheduler_job.job_id
}

output "scheduler_name" {
  description = "Name of the Cloud Scheduler job"
  value       = module.scheduler_job.scheduler_name
}

output "scheduler_service_account_email" {
  description = "Email of the scheduler job service account"
  value       = module.scheduler_job.job_service_account_email
}

# Cloud Tasks Queue outputs
output "queue_name" {
  description = "Name of the Cloud Tasks queue"
  value       = google_cloud_tasks_queue.queue.name
}

output "queue_id" {
  description = "ID of the Cloud Tasks queue"
  value       = google_cloud_tasks_queue.queue.id
}

# Tasks invoker service account
output "tasks_invoker_email" {
  description = "Email of the Cloud Tasks invoker service account"
  value       = google_service_account.tasks_invoker.email
}

output "tasks_invoker_id" {
  description = "ID of the Cloud Tasks invoker service account"
  value       = google_service_account.tasks_invoker.id
}

# GCS Checkpoint Bucket outputs
output "checkpoint_bucket_name" {
  description = "Name of the GCS checkpoint bucket"
  value       = google_storage_bucket.checkpoint_bucket.name
}

output "checkpoint_bucket_url" {
  description = "URL of the GCS checkpoint bucket"
  value       = google_storage_bucket.checkpoint_bucket.url
}
