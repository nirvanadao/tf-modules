# Service account for the Cloud Run job
resource "google_service_account" "job" {
  project      = var.project_id
  account_id   = var.job_name
  display_name = "Service account for ${var.job_name}"
}

# Grant IAM roles to the job service account
resource "google_project_iam_member" "job_account_roles" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.job.email}"
}

# Grant Secret Manager access for each secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  for_each = var.secret_environment_variables

  project   = var.project_id
  secret_id = split("/", each.value)[3]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.job.email}"
}

# Service account for Cloud Scheduler
# Note: Account ID is truncated to fit GCP's 30 character limit
resource "google_service_account" "scheduler" {
  project      = var.project_id
  account_id   = substr("${var.job_name}-sched", 0, 30)
  display_name = "Scheduler service account for ${var.job_name}"
}

# Grant Cloud Scheduler service account permission to invoke the Cloud Run job
resource "google_cloud_run_v2_job_iam_member" "scheduler_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.job.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler.email}"
}
