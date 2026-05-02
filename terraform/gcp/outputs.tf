output "repository_url" {
  description = "Artifact Registry リポジトリの URL。scripts/deploy.sh の REPO_URL 変数に設定する（例: us-central1-docker.pkg.dev/project/poc-dev-app）"
  value       = module.artifact_registry.repository_url
}

output "cloud_run_url" {
  description = "Cloud Run サービスの URL。verify.sh での接続確認に使用"
  value       = module.cloudrun.service_url
}

output "vpn_gateway_ip0" {
  description = "GCP HA VPN Gateway interface0 の外部 IP。AWS terraform.tfvars の gcp_vpn_gateway_ip0 に設定する"
  value       = module.vpn.vpn_gateway_ip0
}

output "vpn_gateway_ip1" {
  description = "GCP HA VPN Gateway interface1 の外部 IP。AWS terraform.tfvars の gcp_vpn_gateway_ip1 に設定する"
  value       = module.vpn.vpn_gateway_ip1
}
