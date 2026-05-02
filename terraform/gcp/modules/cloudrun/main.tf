locals {
  name_prefix = "${var.project}-${var.env}"
}

# Cloud Run 専用サービスアカウント
resource "google_service_account" "cloudrun" {
  account_id   = "${local.name_prefix}-cloudrun-sa"
  display_name = "Cloud Run Service Account for ${local.name_prefix}"
  project      = var.gcp_project_id
}

# IAM: Secret Manager の読み取り権限（リソースレベル）
# プロジェクト全体への付与を避け、対象シークレットのみに絞る
resource "google_secret_manager_secret_iam_member" "cloudrun_secret_access" {
  secret_id = var.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloudrun.email}"
}

# IAM: Artifact Registry 読み取り権限（コンテナイメージ取得用）
resource "google_project_iam_member" "cloudrun_artifact_reader" {
  project = var.gcp_project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloudrun.email}"
}

# Cloud Run v2 サービス
resource "google_cloud_run_v2_service" "app" {
  name     = "${local.name_prefix}-app"
  location = var.region
  project  = var.gcp_project_id

  # インターネットからのアクセスを許可するが、IAM 認証必須（allUsers への run.invoker 付与なし）
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.cloudrun.email

    # 全トラフィックを Direct VPC Egress でルーティング（Aurora への通信を VPN トンネルに流す）
    vpc_access {
      network_interfaces {
        network    = var.network
        subnetwork = var.subnetwork
      }
      egress = "ALL_TRAFFIC"
    }

    containers {
      image = var.image_url

      # GCP Secret Manager のシークレット名を環境変数で渡す
      # アプリ起動時にこの名前でシークレットを取得する
      env {
        name  = "SECRET_NAME"
        value = var.secret_name
      }

      env {
        name  = "GOOGLE_CLOUD_PROJECT"
        value = var.gcp_project_id
      }

      resources {
        limits = {
          memory = "512Mi"
          cpu    = "1"
        }
      }
    }

    # Aurora コールドスタートを考慮して長めのタイムアウトを設定
    timeout = "300s"

    scaling {
      min_instance_count = 0
      max_instance_count = 3
    }
  }
}
