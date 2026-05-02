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

variable "gcp_project_id" {
  type        = string
  description = "GCP プロジェクト ID。terraform.tfvars で設定すること"
}

variable "region" {
  type        = string
  description = "GCP リソースをデプロイするリージョン"
  default     = "us-central1"
}

# ─── Aurora 接続情報（AWS outputs から取得）────────────────────────
variable "aurora_host" {
  type        = string
  description = "Aurora クラスターのエンドポイント。AWS terraform output aurora_endpoint の値を設定する"
}

variable "db_master_password" {
  type        = string
  description = "Aurora マスターパスワード。AWS 側と同じ値を設定すること（コミット禁止）"
  sensitive   = true
}

# ─── HA VPN 設定（AWS outputs から取得）──────────────────────────
# AWS VPN 接続 1（GCP interface0 向け）のトンネルアドレス
variable "aws_tunnel0_tunnel1_address" {
  type        = string
  description = "AWS terraform output tunnel0_tunnel1_address の値。AWS VPN Connection 作成後に設定する"
  default     = ""
}

variable "aws_tunnel0_tunnel2_address" {
  type        = string
  description = "AWS terraform output tunnel0_tunnel2_address の値。AWS VPN Connection 作成後に設定する"
  default     = ""
}

# AWS VPN 接続 2（GCP interface1 向け）のトンネルアドレス
variable "aws_tunnel1_tunnel1_address" {
  type        = string
  description = "AWS terraform output tunnel1_tunnel1_address の値。AWS VPN Connection 作成後に設定する"
  default     = ""
}

variable "aws_tunnel1_tunnel2_address" {
  type        = string
  description = "AWS terraform output tunnel1_tunnel2_address の値。AWS VPN Connection 作成後に設定する"
  default     = ""
}

variable "tunnel1_inside_cidr" {
  type        = string
  description = "AWS VPN tunnel1 の inside CIDR。AWS VPN connection の TunnelInsideCidr から取得（例: 169.254.202.0/30）"
  default     = ""
}

variable "tunnel2_inside_cidr" {
  type        = string
  description = "AWS VPN tunnel2 の inside CIDR"
  default     = ""
}

variable "tunnel3_inside_cidr" {
  type        = string
  description = "AWS VPN tunnel3 の inside CIDR"
  default     = ""
}

variable "tunnel4_inside_cidr" {
  type        = string
  description = "AWS VPN tunnel4 の inside CIDR"
  default     = ""
}

variable "tunnel1_preshared_key" {
  type        = string
  description = "トンネル 1 PSK。AWS terraform.tfvars の tunnel1_preshared_key と同じ値"
  sensitive   = true
}

variable "tunnel2_preshared_key" {
  type        = string
  description = "トンネル 2 PSK。AWS terraform.tfvars の tunnel2_preshared_key と同じ値"
  sensitive   = true
}

variable "tunnel3_preshared_key" {
  type        = string
  description = "トンネル 3 PSK。AWS terraform.tfvars の tunnel3_preshared_key と同じ値"
  sensitive   = true
}

variable "tunnel4_preshared_key" {
  type        = string
  description = "トンネル 4 PSK。AWS terraform.tfvars の tunnel4_preshared_key と同じ値"
  sensitive   = true
}

# ─── Cloud Run イメージ URL ───────────────────────────────────────
variable "app_image_url" {
  type        = string
  description = "Cloud Run にデプロイするコンテナイメージ URL。初回 apply 時はプレースホルダー。scripts/deploy.sh 実行後に実際の URL（Artifact Registry）で再 apply する"
  default     = "us-docker.pkg.dev/cloudrun/container/hello:latest"
}

# ─── Terraform State バックエンド ────────────────────────────────
variable "tfstate_bucket" {
  type        = string
  description = "Terraform state を保管する S3 バケット名（AWS 側と同じバケットを使用）"
}

variable "tfstate_dynamodb_table" {
  type        = string
  description = "Terraform state ロックに使用する DynamoDB テーブル名"
  default     = "terraform-lock"
}
