# Service account for the Cloud Run service
resource "google_service_account" "service" {
  project      = var.project_id
  account_id   = var.service_name
  display_name = "Service account for ${var.service_name}"
}

# Grant IAM roles to the service account
resource "google_project_iam_member" "service_account_roles" {
  for_each = toset(var.service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.service.email}"
}

# Grant Secret Manager access for each secret
resource "google_secret_manager_secret_iam_member" "secret_accessor" {
  for_each = var.secret_environment_variables

  project   = var.project_id
  secret_id = split("/", each.value)[3]
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.service.email}"
}

# Allow unauthenticated access if requested
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  count = var.allow_unauthenticated ? 1 : 0

  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
