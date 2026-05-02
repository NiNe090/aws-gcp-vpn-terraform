terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-tfstate-bucket-name"  # 変更必須: terraform.tfvars の tfstate_bucket と同じ値
    key            = "poc/gcp/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
}

# ─── 必要な GCP API の有効化 ────────────────────────────────────
# disable_on_destroy = false: terraform destroy 時に API を無効化しない（他リソースへの影響防止）

resource "google_project_service" "run" {
  project            = var.gcp_project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  project            = var.gcp_project_id
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "compute" {
  project            = var.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.gcp_project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# ─── Artifact Registry モジュール ────────────────────────────────
module "artifact_registry" {
  source = "./modules/artifact_registry"

  project        = var.project
  env            = var.env
  gcp_project_id = var.gcp_project_id
  region         = var.region

  depends_on = [google_project_service.artifactregistry]
}

# ─── VPC モジュール ──────────────────────────────────────────────
module "vpc" {
  source = "./modules/vpc"

  project        = var.project
  env            = var.env
  gcp_project_id = var.gcp_project_id
  region         = var.region

  depends_on = [google_project_service.compute]
}

# ─── VPN モジュール ──────────────────────────────────────────────
module "vpn" {
  source = "./modules/vpn"

  project        = var.project
  env            = var.env
  gcp_project_id = var.gcp_project_id
  region         = var.region

  network_self_link = module.vpc.network_self_link

  aws_tunnel0_tunnel1_address = var.aws_tunnel0_tunnel1_address
  aws_tunnel0_tunnel2_address = var.aws_tunnel0_tunnel2_address
  aws_tunnel1_tunnel1_address = var.aws_tunnel1_tunnel1_address
  aws_tunnel1_tunnel2_address = var.aws_tunnel1_tunnel2_address

  tunnel1_preshared_key = var.tunnel1_preshared_key
  tunnel2_preshared_key = var.tunnel2_preshared_key
  tunnel3_preshared_key = var.tunnel3_preshared_key
  tunnel4_preshared_key = var.tunnel4_preshared_key

  tunnel1_inside_cidr = var.tunnel1_inside_cidr
  tunnel2_inside_cidr = var.tunnel2_inside_cidr
  tunnel3_inside_cidr = var.tunnel3_inside_cidr
  tunnel4_inside_cidr = var.tunnel4_inside_cidr

  depends_on = [google_project_service.compute]
}

# ─── Secrets モジュール ──────────────────────────────────────────
module "secrets" {
  source = "./modules/secrets"

  project        = var.project
  env            = var.env
  gcp_project_id = var.gcp_project_id

  aurora_host = var.aurora_host
  aurora_port = 3306
  db_username = "poc_user"
  db_password = var.db_master_password
  db_name     = "poc_db"

  depends_on = [google_project_service.secretmanager]
}

# ─── Cloud Run モジュール ────────────────────────────────────────
module "cloudrun" {
  source = "./modules/cloudrun"

  project        = var.project
  env            = var.env
  gcp_project_id = var.gcp_project_id
  region         = var.region

  network    = module.vpc.network_name
  subnetwork = module.vpc.subnetwork_self_link
  secret_id  = module.secrets.secret_id
  secret_name      = module.secrets.secret_name

  # 初回 apply 時はプレースホルダー。deploy.sh 実行後に実際のイメージ URL で再 apply する
  image_url = var.app_image_url

  depends_on = [google_project_service.run, google_project_service.secretmanager, module.artifact_registry]
}
