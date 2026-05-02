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
  description = "GCP リソースを作成するリージョン"
  default     = "us-central1"
}

variable "network_self_link" {
  type        = string
  description = "HA VPN Gateway を作成する VPC ネットワークのセルフリンク。vpc モジュールの output を渡す"
}

variable "gcp_bgp_asn" {
  type        = number
  description = "GCP Cloud Router の BGP ASN。AWS Customer Gateway の bgp_asn と一致させること"
  default     = 65534
}

variable "aws_bgp_asn" {
  type        = number
  description = "AWS VPN Gateway（VGW）の BGP ASN。Cloud Router の peer ASN として設定する"
  default     = 64512
}

variable "aws_vpc_cidr" {
  type        = string
  description = "AWS VPC の CIDR ブロック。VPN トンネル確立後、BGP でルートが自動広告される（参照用）"
  default     = "10.0.0.0/16"
}

# AWS VPN 接続 1（GCP interface0 向け）のトンネルアドレス
variable "aws_tunnel0_tunnel1_address" {
  type        = string
  description = "AWS VPN 接続 1 トンネル 1 の外部 IP（GCP interface0 のトンネル 1 peer IP）"
}

variable "aws_tunnel0_tunnel2_address" {
  type        = string
  description = "AWS VPN 接続 1 トンネル 2 の外部 IP（GCP interface0 のトンネル 2 peer IP）"
}

# AWS VPN 接続 2（GCP interface1 向け）のトンネルアドレス
variable "aws_tunnel1_tunnel1_address" {
  type        = string
  description = "AWS VPN 接続 2 トンネル 1 の外部 IP（GCP interface1 のトンネル 1 peer IP）"
}

variable "aws_tunnel1_tunnel2_address" {
  type        = string
  description = "AWS VPN 接続 2 トンネル 2 の外部 IP（GCP interface1 のトンネル 2 peer IP）"
}

# AWS VPN トンネルの inside CIDR（/30）
# AWS が .1、GCP が .2 を使用して BGP セッションを確立する
variable "tunnel1_inside_cidr" {
  type        = string
  description = "tunnel1 の inside CIDR（例: 169.254.202.0/30）。AWS VPN connection の TunnelInsideCidr から取得"
  default     = ""
}

variable "tunnel2_inside_cidr" {
  type        = string
  description = "tunnel2 の inside CIDR"
  default     = ""
}

variable "tunnel3_inside_cidr" {
  type        = string
  description = "tunnel3 の inside CIDR"
  default     = ""
}

variable "tunnel4_inside_cidr" {
  type        = string
  description = "tunnel4 の inside CIDR"
  default     = ""
}

variable "tunnel1_preshared_key" {
  type        = string
  description = "トンネル 1 PSK（AWS tunnel1_preshared_key と同じ値）"
  sensitive   = true
}

variable "tunnel2_preshared_key" {
  type        = string
  description = "トンネル 2 PSK（AWS tunnel2_preshared_key と同じ値）"
  sensitive   = true
}

variable "tunnel3_preshared_key" {
  type        = string
  description = "トンネル 3 PSK（AWS tunnel3_preshared_key と同じ値）"
  sensitive   = true
}

variable "tunnel4_preshared_key" {
  type        = string
  description = "トンネル 4 PSK（AWS tunnel4_preshared_key と同じ値）"
  sensitive   = true
}
