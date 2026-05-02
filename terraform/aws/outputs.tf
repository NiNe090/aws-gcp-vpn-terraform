output "aurora_endpoint" {
  description = "Aurora クラスターのライターエンドポイント。GCP Secret Manager に登録する"
  value       = module.aurora.cluster_endpoint
}

# HA VPN 用: GCP が接続先 peer IP として使用する AWS VPN トンネルアドレス（4本）
output "tunnel0_tunnel1_address" {
  description = "VPN 接続 1 トンネル 1 AWS 側外部 IP（GCP interface0 向け）"
  value       = module.vpn.tunnel0_tunnel1_address
}

output "tunnel0_tunnel2_address" {
  description = "VPN 接続 1 トンネル 2 AWS 側外部 IP（GCP interface0 向け、冗長）"
  value       = module.vpn.tunnel0_tunnel2_address
}

output "tunnel1_tunnel1_address" {
  description = "VPN 接続 2 トンネル 1 AWS 側外部 IP（GCP interface1 向け）"
  value       = module.vpn.tunnel1_tunnel1_address
}

output "tunnel1_tunnel2_address" {
  description = "VPN 接続 2 トンネル 2 AWS 側外部 IP（GCP interface1 向け、冗長）"
  value       = module.vpn.tunnel1_tunnel2_address
}

output "vpc_id" {
  description = "作成した VPC の ID"
  value       = module.vpc.vpc_id
}

output "secret_arn" {
  description = "Aurora 接続情報を保管する Secrets Manager シークレットの ARN"
  value       = module.secrets.secret_arn
}
