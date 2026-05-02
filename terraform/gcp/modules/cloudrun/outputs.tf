output "service_url" {
  description = "Cloud Run サービスの URL。verify.sh でのエンドポイント確認に使用"
  value       = google_cloud_run_v2_service.app.uri
}

output "service_account_email" {
  description = "Cloud Run サービスアカウントのメールアドレス"
  value       = google_service_account.cloudrun.email
}
