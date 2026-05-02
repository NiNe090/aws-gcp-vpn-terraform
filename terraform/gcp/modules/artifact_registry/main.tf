locals {
  name_prefix = "${var.project}-${var.env}"
}

# Docker イメージ保存用 Artifact Registry リポジトリ
resource "google_artifact_registry_repository" "app" {
  repository_id = "${local.name_prefix}-app"
  location      = var.region
  project       = var.gcp_project_id
  format        = "DOCKER"
  description   = "Cloud Run 検証アプリのコンテナイメージを管理するリポジトリ"
}
