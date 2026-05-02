output "network_name" {
  description = "GCP VPC ネットワーク名。vpn モジュール等で使用"
  value       = google_compute_network.main.name
}

output "network_self_link" {
  description = "GCP VPC ネットワークのセルフリンク。VPN Gateway のネットワーク指定に使用"
  value       = google_compute_network.main.self_link
}

output "subnetwork_name" {
  description = "GCP サブネット名"
  value       = google_compute_subnetwork.main.name
}

output "subnetwork_self_link" {
  description = "GCP サブネットのリソースパス。Cloud Run の Direct VPC Egress 設定に使用"
  value       = "projects/${var.gcp_project_id}/regions/${var.region}/subnetworks/${google_compute_subnetwork.main.name}"
}
