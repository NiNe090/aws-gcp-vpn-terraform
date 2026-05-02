output "vpn_gateway_ip0" {
  description = "GCP HA VPN Gateway の interface0 外部 IP。AWS Customer Gateway (gcp_interface0) の ip_address に設定する"
  value       = google_compute_ha_vpn_gateway.main.vpn_interfaces[0].ip_address
}

output "vpn_gateway_ip1" {
  description = "GCP HA VPN Gateway の interface1 外部 IP。AWS Customer Gateway (gcp_interface1) の ip_address に設定する"
  value       = google_compute_ha_vpn_gateway.main.vpn_interfaces[1].ip_address
}
