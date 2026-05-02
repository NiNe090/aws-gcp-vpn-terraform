output "vpc_id" {
  description = "作成した VPC の ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "パブリックサブネット ID のリスト"
  value       = [aws_subnet.public.id]
}

output "private_subnet_ids" {
  description = "プライベートサブネット ID のリスト（2AZ）。Aurora の DB サブネットグループに使用"
  value       = [aws_subnet.private_a.id, aws_subnet.private_c.id]
}

output "private_route_table_id" {
  description = "プライベートルートテーブルの ID。VPN モジュールでルート追加に使用"
  value       = aws_route_table.private.id
}
