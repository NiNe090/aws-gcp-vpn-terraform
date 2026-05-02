variable "project" {
  type        = string
  description = "プロジェクト名。リソースの命名に使用する（例: poc）"
}

variable "env" {
  type        = string
  description = "環境名。リソースの命名に使用する（例: dev）"
}

variable "vpc_id" {
  type        = string
  description = "Aurora を配置する VPC の ID。vpc モジュールの output を渡す"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "DB サブネットグループに使用するプライベートサブネット ID のリスト（2AZ 必須）"
}

variable "gcp_vpc_cidr" {
  type        = string
  description = "GCP VPC の CIDR ブロック。Aurora セキュリティグループの inbound ルールに使用"
  default     = "10.1.0.0/16"
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC の CIDR ブロック。Aurora セキュリティグループの inbound ルールに使用（内部通信用）"
  default     = "10.0.0.0/16"
}

variable "db_name" {
  type        = string
  description = "Aurora クラスターに作成するデータベース名"
  default     = "poc_db"
}

variable "db_master_username" {
  type        = string
  description = "Aurora クラスターのマスターユーザー名"
  default     = "poc_user"
}

variable "db_master_password" {
  type        = string
  description = "Aurora クラスターのマスターパスワード。terraform.tfvars で設定すること"
  sensitive   = true
}

variable "aurora_min_capacity" {
  type        = number
  description = "Aurora Serverless v2 の最小 ACU 数。0 に設定すると非使用時のコストをほぼゼロにできる"
  default     = 0
}

variable "aurora_max_capacity" {
  type        = number
  description = "Aurora Serverless v2 の最大 ACU 数。POC では 4 に設定してコスト上限を制御"
  default     = 4
}
