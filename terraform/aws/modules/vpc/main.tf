locals {
  name_prefix = "${var.project}-${var.env}"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# インターネットゲートウェイ
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# パブリックサブネット（ap-northeast-1a）
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-subnet-1a"
  }
}

# プライベートサブネット（ap-northeast-1a）
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_a
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "${local.name_prefix}-private-subnet-1a"
  }
}

# プライベートサブネット（ap-northeast-1c）
# Aurora の DB サブネットグループには 2AZ が必要なため追加
resource "aws_subnet" "private_c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr_c
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "${local.name_prefix}-private-subnet-1c"
  }
}

# パブリックルートテーブル（IGW 経由）
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-public-rtb"
  }
}

# プライベートルートテーブル（ローカルのみ。VPN ルートは伝播で追加）
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-private-rtb"
  }
}

# パブリックサブネットとルートテーブルの関連付け
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# プライベートサブネット（1a）とルートテーブルの関連付け
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}

# プライベートサブネット（1c）とルートテーブルの関連付け
resource "aws_route_table_association" "private_c" {
  subnet_id      = aws_subnet.private_c.id
  route_table_id = aws_route_table.private.id
}

# VPN Gateway のルート伝播（GCP CIDR への経路を自動伝播）
# vpn モジュール適用後に有効化されるため、vpn_gateway_id が空の場合はスキップ
resource "aws_vpn_gateway_route_propagation" "private" {
  count          = var.enable_vpn_route_propagation ? 1 : 0
  vpn_gateway_id = var.vpn_gateway_id
  route_table_id = aws_route_table.private.id
}
