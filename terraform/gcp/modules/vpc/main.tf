locals {
  name_prefix = "${var.project}-${var.env}"
}

# VPC ネットワーク（カスタムモード: サブネットを手動管理）
resource "google_compute_network" "main" {
  name                    = "${local.name_prefix}-vpc"
  auto_create_subnetworks = false
  project                 = var.gcp_project_id
}

# サブネット（us-central1, 10.1.0.0/24）
resource "google_compute_subnetwork" "main" {
  name                     = "${local.name_prefix}-subnet"
  ip_cidr_range            = var.vpc_cidr
  region                   = var.region
  network                  = google_compute_network.main.id
  project                  = var.gcp_project_id
  private_ip_google_access = true # Google API へのプライベートアクセスを有効化
}

