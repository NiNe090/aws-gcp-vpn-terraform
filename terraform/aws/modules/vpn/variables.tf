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
  description = "VPN Gateway をアタッチする VPC の ID。vpc モジュールの output を渡す"
}

variable "private_route_table_id" {
  type        = string
  description = "プライベートルートテーブルの ID。VPN GW のルート伝播設定に使用"
}

variable "aws_bgp_asn" {
  type        = number
  description = "AWS VPN Gateway（VGW）の BGP ASN。GCP Cloud Router の peer ASN として指定する"
  default     = 64512
}

variable "gcp_bgp_asn" {
  type        = number
  description = "GCP Cloud Router の BGP ASN。Customer Gateway の bgp_asn として指定する"
  default     = 65534
}

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
  description = "VPN 接続 1 のトンネル 1 PSK（GCP interface0 向け）"
  sensitive   = true
}

variable "tunnel2_preshared_key" {
  type        = string
  description = "VPN 接続 1 のトンネル 2 PSK（GCP interface0 向け、冗長用）"
  sensitive   = true
}

variable "tunnel3_preshared_key" {
  type        = string
  description = "VPN 接続 2 のトンネル 1 PSK（GCP interface1 向け）"
  sensitive   = true
}

variable "tunnel4_preshared_key" {
  type        = string
  description = "VPN 接続 2 のトンネル 2 PSK（GCP interface1 向け、冗長用）"
  sensitive   = true
}
