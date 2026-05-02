variable "project" {
  type        = string
  description = "プロジェクト名。リソースの命名に使用する（例: poc）"
}

variable "env" {
  type        = string
  description = "環境名。リソースの命名に使用する（例: dev）"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP プロジェクト ID"
}

variable "region" {
  type        = string
  description = "Cloud Run サービスをデプロイするリージョン"
  default     = "us-central1"
}

variable "network" {
  type        = string
  description = "VPC ネットワーク名。Direct VPC Egress の network_interfaces に使用"
}

variable "subnetwork" {
  type        = string
  description = "サブネットのセルフリンク。Direct VPC Egress の network_interfaces に使用"
}

variable "secret_id" {
  type        = string
  description = "GCP Secret Manager シークレットのリソース ID。IAM バインディングの作成に使用"
}

variable "secret_name" {
  type        = string
  description = "シークレット名。Cloud Run の SECRET_NAME 環境変数として設定する"
}

variable "image_url" {
  type        = string
  description = "Cloud Run にデプロイするコンテナイメージの URL。app フェーズで Artifact Registry のイメージ URL に更新する"
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest"
}
