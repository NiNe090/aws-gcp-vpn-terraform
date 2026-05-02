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
  description = "Artifact Registry リポジトリを作成するリージョン"
  default     = "us-central1"
}
