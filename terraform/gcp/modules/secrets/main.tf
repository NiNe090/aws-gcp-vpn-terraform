locals {
  name_prefix = "${var.project}-${var.env}"
}

# Aurora 接続情報を保管する GCP Secret Manager シークレット
resource "google_secret_manager_secret" "aurora" {
  secret_id = "${local.name_prefix}-aurora-credentials"
  project   = var.gcp_project_id

  replication {
    auto {}
  }

  labels = {
    env = var.env
  }
}

# シークレットの値（JSON 形式）
# Cloud Run アプリが起動時に取得し、Aurora への接続に使用する
resource "google_secret_manager_secret_version" "aurora" {
  secret = google_secret_manager_secret.aurora.id
  secret_data = jsonencode({
    host     = var.aurora_host
    port     = var.aurora_port
    user     = var.db_username
    password = var.db_password
    dbname   = var.db_name
  })
}
