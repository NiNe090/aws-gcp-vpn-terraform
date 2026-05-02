variable "project" {
  type        = string
  description = "プロジェクト名。リソースの命名に使用する（例: poc）"
}

variable "env" {
  type        = string
  description = "環境名。リソースの命名に使用する（例: dev）"
}

variable "vpc_cidr" {
  type        = string
  description = "AWS VPC の CIDR ブロック"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "パブリックサブネットの CIDR ブロック（ap-northeast-1a）"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr_a" {
  type        = string
  description = "プライベートサブネットの CIDR ブロック（ap-northeast-1a）。Aurora の DB サブネットグループに使用"
  default     = "10.0.10.0/24"
}

variable "private_subnet_cidr_c" {
  type        = string
  description = "プライベートサブネットの CIDR ブロック（ap-northeast-1c）。Aurora の DB サブネットグループに 2AZ 必要なため追加"
  default     = "10.0.11.0/24"
}

variable "vpn_gateway_id" {
  type        = string
  description = "VPN Gateway の ID。プライベートルートテーブルへのルート伝播に使用する。vpn モジュールの output を渡す"
  default     = ""
}

variable "enable_vpn_route_propagation" {
  type        = bool
  description = "true にすると VPN Gateway のルート伝播を有効化する。apply 時に値が確定している必要があるため bool で制御する"
  default     = false
}
