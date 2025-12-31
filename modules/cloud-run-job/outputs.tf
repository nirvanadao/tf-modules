output "job_name" {
  description = "Name of the Cloud Run job"
  value       = google_cloud_run_v2_job.job.name
}

output "job_id" {
  description = "ID of the Cloud Run job"
  value       = google_cloud_run_v2_job.job.id
}

output "scheduler_name" {
  description = "Name of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.scheduler.name
}

output "scheduler_id" {
  description = "ID of the Cloud Scheduler job"
  value       = google_cloud_scheduler_job.scheduler.id
}

output "job_service_account_email" {
  description = "Email of the service account used by Cloud Run job"
  value       = google_service_account.job.email
}

output "job_service_account_id" {
  description = "ID of the job service account"
  value       = google_service_account.job.id
}

output "scheduler_service_account_email" {
  description = "Email of the scheduler service account"
  value       = google_service_account.scheduler.email
}

output "scheduler_service_account_id" {
  description = "ID of the scheduler service account"
  value       = google_service_account.scheduler.id
}
