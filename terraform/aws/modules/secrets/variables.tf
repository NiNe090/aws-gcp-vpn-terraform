variable "project" {
  type        = string
  description = "プロジェクト名。リソースの命名に使用する（例: poc）"
}

variable "env" {
  type        = string
  description = "環境名。リソースの命名に使用する（例: dev）"
}

variable "aurora_host" {
  type        = string
  description = "Aurora クラスターのエンドポイントホスト名。aurora モジュールの cluster_endpoint を渡す"
}

variable "aurora_port" {
  type        = number
  description = "Aurora クラスターのポート番号"
  default     = 3306
}

variable "db_username" {
  type        = string
  description = "Aurora 接続に使用するデータベースユーザー名"
}

variable "db_password" {
  type        = string
  description = "Aurora 接続に使用するデータベースパスワード"
  sensitive   = true
}

variable "db_name" {
  type        = string
  description = "接続先のデータベース名"
}
