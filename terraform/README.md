# Terraform デプロイ手順

GCP-AWS MultiCloud POC のインフラをデプロイするための手順書です。

## 前提条件

- Terraform >= 1.5
- AWS CLI（認証済み）
- gcloud CLI（認証済み: `gcloud auth application-default login`）
- S3 バケット・DynamoDB テーブルが作成済み（state バックエンド用）

---

## デプロイ順序の概要

VPN の相互接続のため、以下の順序でデプロイします。

```
[1] AWS apply (仮 GCP IP で VPN 作成)
     ↓ VPN トンネルアドレスが確定
[2] GCP apply (AWS トンネルアドレスを指定して VPN・全リソース作成)
     ↓ GCP VPN Gateway の外部 IP が確定
[3] AWS re-apply (Customer Gateway の IP を GCP 実 IP に更新)
     ↓ BGP セッション確立・VPN トンネル UP
[4] docker build & push (scripts/deploy.sh)
     ↓ Artifact Registry にイメージが登録
[5] GCP re-apply (app_image_url を実際のイメージ URL に更新)
     ↓ Cloud Run が実イメージでデプロイ
```

---

## ステップ 1: AWS 初回 apply

### terraform.tfvars の作成

```hcl
# terraform/aws/terraform.tfvars
tfstate_bucket         = "YOUR_S3_BUCKET_NAME"
db_master_password     = "YOUR_DB_PASSWORD"
tunnel1_preshared_key  = "YOUR_PSK_1"
tunnel2_preshared_key  = "YOUR_PSK_2"
tunnel3_preshared_key  = "YOUR_PSK_3"
tunnel4_preshared_key  = "YOUR_PSK_4"
# gcp_vpn_gateway_ip0/ip1 は初回デフォルト値（0.0.0.0/0.0.0.1）のまま
```

### 実行

```bash
cd terraform/aws
terraform init
terraform plan
terraform apply
```

### 出力値の確認

```bash
terraform output
# aurora_endpoint          → GCP secrets モジュールの aurora_host に使用
# tunnel0_tunnel1_address  → GCP variables の aws_tunnel0_tunnel1_address に使用
# tunnel0_tunnel2_address  → GCP variables の aws_tunnel0_tunnel2_address に使用
# tunnel1_tunnel1_address  → GCP variables の aws_tunnel1_tunnel1_address に使用
# tunnel1_tunnel2_address  → GCP variables の aws_tunnel1_tunnel2_address に使用
```

---

## ステップ 2: GCP 初回 apply

### terraform.tfvars の作成

```hcl
# terraform/gcp/terraform.tfvars
tfstate_bucket             = "YOUR_S3_BUCKET_NAME"
gcp_project_id             = "YOUR_GCP_PROJECT_ID"
aurora_host                = "AURORA_ENDPOINT_FROM_STEP1"
db_master_password         = "YOUR_DB_PASSWORD"  # AWS と同じ値
tunnel1_preshared_key      = "YOUR_PSK_1"
tunnel2_preshared_key      = "YOUR_PSK_2"
tunnel3_preshared_key      = "YOUR_PSK_3"
tunnel4_preshared_key      = "YOUR_PSK_4"
aws_tunnel0_tunnel1_address = "TUNNEL0_TUNNEL1_FROM_STEP1"
aws_tunnel0_tunnel2_address = "TUNNEL0_TUNNEL2_FROM_STEP1"
aws_tunnel1_tunnel1_address = "TUNNEL1_TUNNEL1_FROM_STEP1"
aws_tunnel1_tunnel2_address = "TUNNEL1_TUNNEL2_FROM_STEP1"
# app_image_url はデフォルト値（プレースホルダー）のまま
```

### 実行

```bash
cd terraform/gcp
terraform init
terraform plan
terraform apply
```

### 出力値の確認

```bash
terraform output
# vpn_gateway_ip0   → AWS terraform.tfvars の gcp_vpn_gateway_ip0 に使用
# vpn_gateway_ip1   → AWS terraform.tfvars の gcp_vpn_gateway_ip1 に使用
# repository_url    → scripts/deploy.sh の REPO_URL に使用
# cloud_run_url     → scripts/verify.sh での確認に使用
```

---

## ステップ 3: AWS 再 apply（Customer Gateway IP の更新）

### terraform.tfvars を更新

```hcl
# terraform/aws/terraform.tfvars に追記
gcp_vpn_gateway_ip0 = "VPN_GATEWAY_IP0_FROM_STEP2"
gcp_vpn_gateway_ip1 = "VPN_GATEWAY_IP1_FROM_STEP2"
```

### 実行

```bash
cd terraform/aws
terraform apply
```

これにより BGP セッションが確立し、VPN トンネルが UP 状態になります。

---

## ステップ 4: コンテナイメージのビルドと push

```bash
# Artifact Registry への認証
gcloud auth configure-docker us-central1-docker.pkg.dev

# ビルドと push
REPO_URL=$(cd terraform/gcp && terraform output -raw repository_url)
bash scripts/deploy.sh "${REPO_URL}" v1.0.0
```

`deploy.sh` の詳細は [scripts/deploy.sh](../scripts/deploy.sh) を参照。

---

## ステップ 5: GCP 再 apply（Cloud Run イメージ URL の更新）

### terraform.tfvars を更新

```hcl
# terraform/gcp/terraform.tfvars に追記
# deploy.sh 実行時に出力される "app_image_url = ..." の値をそのまま転記する
app_image_url = "REPOSITORY_URL_FROM_STEP2:TAG"
# 例: us-central1-docker.pkg.dev/my-project/poc-dev-app:v1.0.0
```

### 実行

```bash
cd terraform/gcp
terraform apply
```

---

## ステップ 6: 動作確認

```bash
CLOUD_RUN_URL=$(cd terraform/gcp && terraform output -raw cloud_run_url)
bash scripts/verify.sh "${CLOUD_RUN_URL}"
```

---

## terraform destroy の手順

リソースを削除する際は、作成の逆順で実行します。

```bash
# 1. GCP リソースの削除
cd terraform/gcp
terraform destroy

# 2. AWS リソースの削除
cd terraform/aws
terraform destroy
```

> **注意**: Aurora クラスターの削除には数分かかります。
> Secret Manager のシークレットは `recovery_window_in_days = 0` のため即時削除されます。

---

## モジュール構成

### AWS (`terraform/aws/`)

| モジュール | 説明 |
|-----------|------|
| `modules/vpc` | VPC・サブネット・ルートテーブル |
| `modules/aurora` | Aurora Serverless v2 クラスター |
| `modules/vpn` | HA VPN（Customer Gateway × 2、VPN Connection × 2） |
| `modules/secrets` | Secrets Manager（DB 接続情報） |

### GCP (`terraform/gcp/`)

| モジュール | 説明 |
|-----------|------|
| `modules/vpc` | VPC・サブネット・Serverless VPC Access コネクタ |
| `modules/vpn` | HA VPN Gateway・Cloud Router・BGP トンネル × 4 |
| `modules/secrets` | Secret Manager（Aurora 接続情報） |
| `modules/artifact_registry` | Artifact Registry Docker リポジトリ |
| `modules/cloudrun` | Cloud Run v2 サービス・サービスアカウント・IAM |

---

## トラブルシューティング

### VPN トンネルが UP にならない場合

1. AWS コンソール → VPN Connections → Tunnel Details でステータス確認
2. GCP コンソール → Hybrid Connectivity → VPN トンネルのステータス確認
3. PSK が両側で一致しているか確認
4. BGP ASN の設定確認（AWS: 64512、GCP: 65534）

### Cloud Run が Aurora に接続できない場合

1. VPN トンネルが UP であることを確認（上記参照）
2. Aurora の Security Group で GCP サブネット（10.1.0.0/16）からの 3306 が許可されているか確認
3. VPC Access コネクタのステータス確認（GCP コンソール → VPC → Serverless VPC Access）
4. Secret Manager のシークレットに正しい Aurora エンドポイントが設定されているか確認
