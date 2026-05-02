output "secret_arn" {
  description = "Aurora 接続情報シークレットの ARN。IAM ポリシーや他サービスからの参照に使用"
  value       = aws_secretsmanager_secret.aurora.arn
}

output "secret_name" {
  description = "Aurora 接続情報シークレットの名前"
  value       = aws_secretsmanager_secret.aurora.name
}
