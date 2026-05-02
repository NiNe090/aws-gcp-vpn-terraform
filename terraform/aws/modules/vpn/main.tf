locals {
  name_prefix = "${var.project}-${var.env}"
  # GCP apply 前はプレースホルダー IP（0.0.0.0/0.0.0.1）のため Customer GW / VPN Connection を作成しない
  vpn_ready = var.gcp_vpn_gateway_ip0 != "0.0.0.0"
}

# 仮想プライベートゲートウェイ（VGW）
resource "aws_vpn_gateway" "main" {
  vpc_id          = var.vpc_id
  amazon_side_asn = var.aws_bgp_asn

  tags = {
    Name = "${local.name_prefix}-vgw"
  }
}

# カスタマーゲートウェイ（CGW）× 2
# GCP HA VPN は 2 つの外部 IP を持つため、それぞれに CGW を作成する
resource "aws_customer_gateway" "gcp_interface0" {
  count      = local.vpn_ready ? 1 : 0
  bgp_asn    = var.gcp_bgp_asn
  ip_address = var.gcp_vpn_gateway_ip0
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-cgw-gcp-if0"
  }
}

resource "aws_customer_gateway" "gcp_interface1" {
  count      = local.vpn_ready ? 1 : 0
  bgp_asn    = var.gcp_bgp_asn
  ip_address = var.gcp_vpn_gateway_ip1
  type       = "ipsec.1"

  tags = {
    Name = "${local.name_prefix}-cgw-gcp-if1"
  }
}

# Site-to-Site VPN 接続 1（GCP HA VPN interface0 向け）
# BGP 動的ルーティング、IKEv2/AES-256
resource "aws_vpn_connection" "tunnel0" {
  count               = local.vpn_ready ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.gcp_interface0[0].id
  type                = "ipsec.1"
  static_routes_only  = false # BGP 動的ルーティングを使用

  tunnel1_preshared_key = var.tunnel1_preshared_key
  tunnel2_preshared_key = var.tunnel2_preshared_key

  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name = "${local.name_prefix}-vpn-if0"
  }
}

# Site-to-Site VPN 接続 2（GCP HA VPN interface1 向け）
resource "aws_vpn_connection" "tunnel1" {
  count               = local.vpn_ready ? 1 : 0
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.gcp_interface1[0].id
  type                = "ipsec.1"
  static_routes_only  = false

  tunnel1_preshared_key = var.tunnel3_preshared_key
  tunnel2_preshared_key = var.tunnel4_preshared_key

  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]

  tunnel2_ike_versions                 = ["ikev2"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_dh_group_numbers      = [14]

  tags = {
    Name = "${local.name_prefix}-vpn-if1"
  }
}
