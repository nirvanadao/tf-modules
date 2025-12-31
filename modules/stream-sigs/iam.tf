# Grant worker service account access to publish to Pub/Sub
resource "google_pubsub_topic_iam_member" "worker_publisher" {
  project = var.project_id
  topic   = module.pubsub_topic.topic_name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${module.worker_service.service_account_email}"
}

# Grant worker service account access to GCS checkpoint bucket
resource "google_storage_bucket_iam_member" "worker_checkpoint_access" {
  bucket = google_storage_bucket.checkpoint_bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${module.worker_service.service_account_email}"
}
