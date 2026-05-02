locals {
  name_prefix = "${var.project}-${var.env}"
}

# Aurora 用セキュリティグループ
# inbound: TCP 3306 を GCP VPC CIDR と AWS VPC 内部からのみ許可
resource "aws_security_group" "aurora" {
  name        = "${local.name_prefix}-aurora-sg"
  description = "Security group for Aurora Serverless v2. Allows MySQL from GCP VPC and AWS VPC only."
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL from GCP VPC via VPN"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.gcp_vpc_cidr]
  }

  ingress {
    description = "MySQL from AWS VPC internal"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.aws_vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name_prefix}-aurora-sg"
  }
}

# DB サブネットグループ（プライベートサブネット 2AZ）
resource "aws_db_subnet_group" "aurora" {
  name        = "${local.name_prefix}-aurora-subnet-group"
  description = "Subnet group for Aurora Serverless v2. Spans 2 AZs for availability."
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name = "${local.name_prefix}-aurora-subnet-group"
  }
}

# Aurora Serverless v2 クラスター（MySQL 8.0 互換）
resource "aws_rds_cluster" "aurora" {
  cluster_identifier     = "${local.name_prefix}-aurora"
  engine                 = "aurora-mysql"
  engine_mode            = "provisioned"
  engine_version         = "8.0.mysql_aurora.3.08.2"
  database_name          = var.db_name
  master_username        = var.db_master_username
  master_password        = var.db_master_password
  db_subnet_group_name   = aws_db_subnet_group.aurora.name
  vpc_security_group_ids = [aws_security_group.aurora.id]
  skip_final_snapshot    = true
  deletion_protection    = false # POC のため destroy を可能に

  serverlessv2_scaling_configuration {
    min_capacity = var.aurora_min_capacity
    max_capacity = var.aurora_max_capacity
  }

  tags = {
    Name = "${local.name_prefix}-aurora"
  }
}

# Aurora Serverless v2 インスタンス
resource "aws_rds_cluster_instance" "aurora" {
  identifier           = "${local.name_prefix}-aurora-instance-1"
  cluster_identifier   = aws_rds_cluster.aurora.id
  instance_class       = "db.serverless"
  engine               = aws_rds_cluster.aurora.engine
  engine_version       = aws_rds_cluster.aurora.engine_version
  publicly_accessible  = false # プライベートサブネットのみ。外部からのアクセスを禁止
  db_subnet_group_name = aws_db_subnet_group.aurora.name

  tags = {
    Name = "${local.name_prefix}-aurora-instance-1"
  }
}
