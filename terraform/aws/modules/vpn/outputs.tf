output "vpn_gateway_id" {
  description = "仮想プライベートゲートウェイ（VGW）の ID。vpc モジュールのルート伝播設定に使用"
  value       = aws_vpn_gateway.main.id
}

# VPN 接続 1（GCP interface0 向け）のトンネルアドレス
output "tunnel0_tunnel1_address" {
  description = "VPN 接続 1 のトンネル 1 AWS 側外部 IP。GCP の VPN トンネル設定で peer IP として使用"
  value       = length(aws_vpn_connection.tunnel0) > 0 ? aws_vpn_connection.tunnel0[0].tunnel1_address : ""
}

output "tunnel0_tunnel2_address" {
  description = "VPN 接続 1 のトンネル 2 AWS 側外部 IP。GCP の VPN トンネル設定で peer IP として使用"
  value       = length(aws_vpn_connection.tunnel0) > 0 ? aws_vpn_connection.tunnel0[0].tunnel2_address : ""
}

# VPN 接続 2（GCP interface1 向け）のトンネルアドレス
output "tunnel1_tunnel1_address" {
  description = "VPN 接続 2 のトンネル 1 AWS 側外部 IP。GCP の VPN トンネル設定で peer IP として使用"
  value       = length(aws_vpn_connection.tunnel1) > 0 ? aws_vpn_connection.tunnel1[0].tunnel1_address : ""
}

output "tunnel1_tunnel2_address" {
  description = "VPN 接続 2 のトンネル 2 AWS 側外部 IP。GCP の VPN トンネル設定で peer IP として使用"
  value       = length(aws_vpn_connection.tunnel1) > 0 ? aws_vpn_connection.tunnel1[0].tunnel2_address : ""
}
