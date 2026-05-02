output "repository_url" {
  description = "Artifact Registry リポジトリの URL。docker push / Cloud Run の image_url に使用する（例: us-central1-docker.pkg.dev/project/poc-dev-app）"
  value       = "${var.region}-docker.pkg.dev/${var.gcp_project_id}/${google_artifact_registry_repository.app.repository_id}"
}

output "repository_id" {
  description = "Artifact Registry リポジトリ ID"
  value       = google_artifact_registry_repository.app.repository_id
}
