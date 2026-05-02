variable "project" {
  type        = string
  description = "プロジェクト名。全リソースの命名プレフィックスに使用する（例: poc）"
  default     = "poc"
}

variable "env" {
  type        = string
  description = "環境名。全リソースの命名プレフィックスに使用する（例: dev）"
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS リソースをデプロイするリージョン"
  default     = "ap-northeast-1"
}

variable "db_master_password" {
  type        = string
  description = "Aurora マスターパスワード。terraform.tfvars で設定すること（コミット禁止）"
  sensitive   = true
}

# ─── GCP HA VPN 設定 ─────────────────────────────────────────────
# GCP HA VPN Gateway は 2 つの外部 IP（interface0, interface1）を持つ
# それぞれに対して AWS Customer Gateway を作成するため、2 つの IP が必要

variable "gcp_vpn_gateway_ip0" {
  type        = string
  description = "GCP HA VPN Gateway の interface0 外部 IP。GCP apply 後に確定する"
  default     = "0.0.0.0"
}

variable "gcp_vpn_gateway_ip1" {
  type        = string
  description = "GCP HA VPN Gateway の interface1 外部 IP。GCP apply 後に確定する"
  default     = "0.0.0.1"
}

variable "tunnel1_preshared_key" {
  type        = string
  description = "VPN 接続 1 トンネル 1 の PSK（GCP interface0 向け）"
  sensitive   = true
}

variable "tunnel2_preshared_key" {
  type        = string
  description = "VPN 接続 1 トンネル 2 の PSK（GCP interface0 向け、冗長用）"
  sensitive   = true
}

variable "tunnel3_preshared_key" {
  type        = string
  description = "VPN 接続 2 トンネル 1 の PSK（GCP interface1 向け）"
  sensitive   = true
}

variable "tunnel4_preshared_key" {
  type        = string
  description = "VPN 接続 2 トンネル 2 の PSK（GCP interface1 向け、冗長用）"
  sensitive   = true
}

variable "tfstate_bucket" {
  type        = string
  description = "Terraform state を保管する S3 バケット名"
}

variable "tfstate_dynamodb_table" {
  type        = string
  description = "Terraform state ロックに使用する DynamoDB テーブル名"
  default     = "terraform-lock"
}
