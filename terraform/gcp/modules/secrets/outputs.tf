output "secret_id" {
  description = "GCP Secret Manager シークレットのリソース ID。cloudrun モジュールの IAM バインディングに使用"
  value       = google_secret_manager_secret.aurora.id
}

output "secret_name" {
  description = "シークレット名。Cloud Run の環境変数 SECRET_NAME として渡す"
  value       = google_secret_manager_secret.aurora.secret_id
}
