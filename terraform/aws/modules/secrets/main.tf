locals {
  name_prefix = "${var.project}-${var.env}"
}

# Aurora 接続情報を保管する Secrets Manager シークレット
resource "aws_secretsmanager_secret" "aurora" {
  name        = "${local.name_prefix}-aurora-credentials"
  description = "Aurora Serverless v2 の接続情報（host, port, username, password, dbname）"

  # POC のため削除保護期間をゼロに設定（terraform destroy で即削除可能）
  recovery_window_in_days = 0

  tags = {
    Name = "${local.name_prefix}-aurora-credentials"
  }
}

# シークレットの値（JSON 形式）
resource "aws_secretsmanager_secret_version" "aurora" {
  secret_id = aws_secretsmanager_secret.aurora.id
  secret_string = jsonencode({
    host     = var.aurora_host
    port     = var.aurora_port
    username = var.db_username
    password = var.db_password
    dbname   = var.db_name
  })
}
