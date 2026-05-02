locals {
  name_prefix  = "${var.project}-${var.env}"
  # AWS apply 前はトンネルアドレスが空のため External GW・トンネル・BGP をスキップ
  tunnels_ready = var.aws_tunnel0_tunnel1_address != ""
}

# GCP HA VPN Gateway
# 2 つのインターフェース（外部 IP）を持つ。AWS の 2 つの VPN 接続と対応させる
resource "google_compute_ha_vpn_gateway" "main" {
  name    = "${local.name_prefix}-ha-vpn-gw"
  network = var.network_self_link
  region  = var.region
  project = var.gcp_project_id
}

# AWS VPN を表す外部 VPN Gateway リソース
# AWS は 4 本のトンネルアドレスを提供する（接続 1 × 2トンネル + 接続 2 × 2トンネル）
resource "google_compute_external_vpn_gateway" "aws" {
  count           = local.tunnels_ready ? 1 : 0
  name            = "${local.name_prefix}-aws-vpn-gw"
  project         = var.gcp_project_id
  redundancy_type = "FOUR_IPS_REDUNDANCY"

  interface {
    id         = 0
    ip_address = var.aws_tunnel0_tunnel1_address
  }
  interface {
    id         = 1
    ip_address = var.aws_tunnel0_tunnel2_address
  }
  interface {
    id         = 2
    ip_address = var.aws_tunnel1_tunnel1_address
  }
  interface {
    id         = 3
    ip_address = var.aws_tunnel1_tunnel2_address
  }
}

# Cloud Router（BGP ルーティング用）
resource "google_compute_router" "main" {
  name    = "${local.name_prefix}-router"
  network = var.network_self_link
  region  = var.region
  project = var.gcp_project_id

  bgp {
    asn = var.gcp_bgp_asn
  }
}

# VPN トンネル × 4（HA VPN: interface0 × 2 本 + interface1 × 2 本）

resource "google_compute_vpn_tunnel" "tunnel1" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${local.name_prefix}-tunnel1"
  region                          = var.region
  project                         = var.gcp_project_id
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id
  peer_external_gateway_interface = 0
  shared_secret                   = var.tunnel1_preshared_key
  router                          = google_compute_router.main.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel2" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${local.name_prefix}-tunnel2"
  region                          = var.region
  project                         = var.gcp_project_id
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id
  peer_external_gateway_interface = 1
  shared_secret                   = var.tunnel2_preshared_key
  router                          = google_compute_router.main.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel3" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${local.name_prefix}-tunnel3"
  region                          = var.region
  project                         = var.gcp_project_id
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id
  peer_external_gateway_interface = 2
  shared_secret                   = var.tunnel3_preshared_key
  router                          = google_compute_router.main.id
  ike_version                     = 2
}

resource "google_compute_vpn_tunnel" "tunnel4" {
  count                           = local.tunnels_ready ? 1 : 0
  name                            = "${local.name_prefix}-tunnel4"
  region                          = var.region
  project                         = var.gcp_project_id
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id
  vpn_gateway_interface           = 1
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id
  peer_external_gateway_interface = 3
  shared_secret                   = var.tunnel4_preshared_key
  router                          = google_compute_router.main.id
  ike_version                     = 2
}

# Cloud Router インターフェース & BGP ピア × 4

resource "google_compute_router_interface" "tunnel1" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${local.name_prefix}-if-tunnel1"
  router     = google_compute_router.main.name
  region     = var.region
  project    = var.gcp_project_id
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1[0].name
  # GCP 側の BGP inside IP（AWS が .1、GCP が .2 を使用）
  ip_range   = var.tunnel1_inside_cidr != "" ? "${cidrhost(var.tunnel1_inside_cidr, 2)}/${split("/", var.tunnel1_inside_cidr)[1]}" : null
}

resource "google_compute_router_peer" "tunnel1" {
  count                     = local.tunnels_ready ? 1 : 0
  name                      = "${local.name_prefix}-peer-tunnel1"
  router                    = google_compute_router.main.name
  region                    = var.region
  project                   = var.gcp_project_id
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel1[0].name
  peer_ip_address           = var.tunnel1_inside_cidr != "" ? cidrhost(var.tunnel1_inside_cidr, 1) : null
}

resource "google_compute_router_interface" "tunnel2" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${local.name_prefix}-if-tunnel2"
  router     = google_compute_router.main.name
  region     = var.region
  project    = var.gcp_project_id
  vpn_tunnel = google_compute_vpn_tunnel.tunnel2[0].name
  ip_range   = var.tunnel2_inside_cidr != "" ? "${cidrhost(var.tunnel2_inside_cidr, 2)}/${split("/", var.tunnel2_inside_cidr)[1]}" : null
}

resource "google_compute_router_peer" "tunnel2" {
  count                     = local.tunnels_ready ? 1 : 0
  name                      = "${local.name_prefix}-peer-tunnel2"
  router                    = google_compute_router.main.name
  region                    = var.region
  project                   = var.gcp_project_id
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel2[0].name
  peer_ip_address           = var.tunnel2_inside_cidr != "" ? cidrhost(var.tunnel2_inside_cidr, 1) : null
}

resource "google_compute_router_interface" "tunnel3" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${local.name_prefix}-if-tunnel3"
  router     = google_compute_router.main.name
  region     = var.region
  project    = var.gcp_project_id
  vpn_tunnel = google_compute_vpn_tunnel.tunnel3[0].name
  ip_range   = var.tunnel3_inside_cidr != "" ? "${cidrhost(var.tunnel3_inside_cidr, 2)}/${split("/", var.tunnel3_inside_cidr)[1]}" : null
}

resource "google_compute_router_peer" "tunnel3" {
  count                     = local.tunnels_ready ? 1 : 0
  name                      = "${local.name_prefix}-peer-tunnel3"
  router                    = google_compute_router.main.name
  region                    = var.region
  project                   = var.gcp_project_id
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel3[0].name
  peer_ip_address           = var.tunnel3_inside_cidr != "" ? cidrhost(var.tunnel3_inside_cidr, 1) : null
}

resource "google_compute_router_interface" "tunnel4" {
  count      = local.tunnels_ready ? 1 : 0
  name       = "${local.name_prefix}-if-tunnel4"
  router     = google_compute_router.main.name
  region     = var.region
  project    = var.gcp_project_id
  vpn_tunnel = google_compute_vpn_tunnel.tunnel4[0].name
  ip_range   = var.tunnel4_inside_cidr != "" ? "${cidrhost(var.tunnel4_inside_cidr, 2)}/${split("/", var.tunnel4_inside_cidr)[1]}" : null
}

resource "google_compute_router_peer" "tunnel4" {
  count                     = local.tunnels_ready ? 1 : 0
  name                      = "${local.name_prefix}-peer-tunnel4"
  router                    = google_compute_router.main.name
  region                    = var.region
  project                   = var.gcp_project_id
  peer_asn                  = var.aws_bgp_asn
  advertised_route_priority = 100
  interface                 = google_compute_router_interface.tunnel4[0].name
  peer_ip_address           = var.tunnel4_inside_cidr != "" ? cidrhost(var.tunnel4_inside_cidr, 1) : null
}
