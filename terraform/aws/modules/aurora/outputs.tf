output "cluster_endpoint" {
  description = "Aurora クラスターのライターエンドポイント。アプリケーションの接続先として使用"
  value       = aws_rds_cluster.aurora.endpoint
}

output "port" {
  description = "Aurora クラスターのポート番号（MySQL: 3306）"
  value       = aws_rds_cluster.aurora.port
}

output "security_group_id" {
  description = "Aurora セキュリティグループの ID。追加のルール設定が必要な場合に参照"
  value       = aws_security_group.aurora.id
}
