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
  description = "GCP プロジェクト ID。リソースの作成先プロジェクトを指定する"
}

variable "region" {
  type        = string
  description = "GCP リソースを作成するリージョン"
  default     = "us-central1"
}

variable "vpc_cidr" {
  type        = string
  description = "GCP VPC サブネットの CIDR ブロック"
  default     = "10.1.0.0/24"
}

