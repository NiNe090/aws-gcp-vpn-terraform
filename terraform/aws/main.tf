terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "your-tfstate-bucket-name"  # 変更必須: terraform.tfvars の tfstate_bucket と同じ値
    key            = "poc/aws/terraform.tfstate"
    region         = "ap-northeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC モジュール
module "vpc" {
  source = "./modules/vpc"

  project                      = var.project
  env                          = var.env
  vpn_gateway_id               = module.vpn.vpn_gateway_id
  enable_vpn_route_propagation = true
}

# Aurora モジュール
module "aurora" {
  source = "./modules/aurora"

  project            = var.project
  env                = var.env
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  db_master_password = var.db_master_password
}

# VPN モジュール（HA VPN 対応: GCP interface0/1 それぞれに VPN 接続を作成）
module "vpn" {
  source = "./modules/vpn"

  project                = var.project
  env                    = var.env
  vpc_id                 = module.vpc.vpc_id
  private_route_table_id = module.vpc.private_route_table_id
  gcp_vpn_gateway_ip0    = var.gcp_vpn_gateway_ip0
  gcp_vpn_gateway_ip1    = var.gcp_vpn_gateway_ip1
  tunnel1_preshared_key  = var.tunnel1_preshared_key
  tunnel2_preshared_key  = var.tunnel2_preshared_key
  tunnel3_preshared_key  = var.tunnel3_preshared_key
  tunnel4_preshared_key  = var.tunnel4_preshared_key
}

# Secrets Manager モジュール
module "secrets" {
  source = "./modules/secrets"

  project     = var.project
  env         = var.env
  aurora_host = module.aurora.cluster_endpoint
  aurora_port = module.aurora.port
  db_username = "poc_user"
  db_password = var.db_master_password
  db_name     = "poc_db"
}
