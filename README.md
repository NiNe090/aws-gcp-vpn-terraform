---
title: AWS と GCP を VPN で繋ぐには何が必要か？ 仕組みから理解するマルチクラウド VPN 接続
tags:
  - AWS
  - GCP
  - Terraform
  - VPN
  - マルチクラウド
private: false
updated_at: ''
id: null
organization_url_name: null
slide: false
ignorePublish: false
---

## はじめに

クラウドのシェア率は AWS / Azure / Google Cloud の 3 強が続いていますが、近年は AWS との差が縮まりつつあります。そうした状況の中で、AWS と他のクラウドサービスを組み合わせたマルチクラウド連携をする機会というのも増えていくのかなと考えています。

今回はそのマルチクラウド連携で、VPN を用いたやり方を実践してみました。

具体的には **GCP の Cloud Runから、VPN トンネルを経由して AWS の Aurora（MySQL）に接続する** という構成を構築しました。

## VPN 接続に必要な要素

AWS と GCP を VPN で繋ぐには、以下の要素が必要です。

| 必要な要素 | なぜ必要か | AWS での実現手段 | GCP での実現手段 |
|-----------|----------|-----------------|-----------------|
| VPN Gateway | 各クラウドに VPN の「出入口」がないとトンネルを張れない | VPN Gateway（VGW） | HA VPN Gateway |
| 相手の情報登録 | IP はトンネルの物理的な接続先、ASN は BGP で経路交換する相手の識別に必要。IP だけではトンネルは張れても経路交換ができず通信できない | Customer Gateway（CGW） | External VPN Gateway |
| IPsec トンネル | 暗号化された通信路がないと、パケットを安全に送れない | VPN Connection | VPN Tunnel |
| BGP ルーティング | 「どの IP 宛のパケットをトンネルに流すか」を自動で教え合う仕組み | VGW 内蔵（自動） | Cloud Router + BGP Peer |
| ルートテーブル反映 | BGP で学習した経路を VPC のルーティングに反映しないと、実際のパケットが流れない | VPN Gateway Route Propagation | Cloud Router が自動反映 |

これらの要素を、実際に作る順番に沿って解説していきます。

ただし、AWS と GCP はお互いの IP アドレスが必要になる循環依存があるため、1 回の操作では完結しません。以下の順番で段階的に構築します。

```
Step 1: AWS 側 ── VPN Gateway を作る
Step 2: GCP 側 ── HA VPN Gateway を作る → 外部 IP が 2 つ払い出される
Step 3: AWS 側 ── GCP の IP を使って Customer Gateway + VPN Connection を作る
                   → トンネル用の外部 IP が 4 つ払い出される
Step 4: GCP 側 ── AWS の IP を使って External VPN Gateway + トンネルを作る
Step 5: GCP 側 ── Cloud Router で BGP を設定する
Step 6: AWS 側 ── ルートテーブルに VPN の経路を伝播させる
```

## Step 1: AWS 側に VPN Gateway を作る【VPN Gateway】

最初に、AWS 側の VPN の「出入口」を作ります。「仮想プライベートゲートウェイ（VGW）」と呼ばれるリソースで、VPC にアタッチします。

```hcl
# terraform/aws/modules/vpn/main.tf
resource "aws_vpn_gateway" "main" {
  vpc_id          = var.vpc_id
  amazon_side_asn = 64512  # ← BGP の AS 番号（Step 5 で詳しく説明）
}
```

`amazon_side_asn = 64512` は、後で BGP ルーティングに使う「AWS 側のネットワーク識別番号」です。ここでは「後で使う番号を先に決めておく」くらいの理解で大丈夫です。

この時点では、VPN Gateway に外部 IP はまだ割り当てられません。AWS の場合、外部 IP は Step 3 で VPN Connection を作った時に初めて払い出されます。

## Step 2: GCP 側に HA VPN Gateway を作る【VPN Gateway】

次に、GCP 側の VPN の「出入口」を作ります。GCP では「HA VPN Gateway」を使います。

```hcl
# terraform/gcp/modules/vpn/main.tf
resource "google_compute_ha_vpn_gateway" "main" {
  name    = "poc-dev-ha-vpn-gw"
  network = var.network_self_link  # アタッチ先の VPC
  region  = "us-central1"
}
```

**ここが AWS との大きな違い**: このリソースを作った瞬間に、GCP から外部 IP が 2 つ自動的に払い出されます。

```
GCP HA VPN Gateway
├── interface0: 34.xxx.xxx.1  ← 自動払い出し
└── interface1: 34.xxx.xxx.2  ← 自動払い出し
```

HA（High Availability）は冗長構成のことで、2 つのインターフェースを持つことで片方が落ちても通信が継続します。

**この 2 つの IP が、次の Step 3 で AWS 側に渡す情報になります。**

## Step 3: AWS 側に Customer Gateway と VPN Connection を作る【相手の情報登録 + IPsec トンネル】

GCP の外部 IP が確定したので、AWS 側に「相手先（GCP）の情報」と「暗号化トンネル」を作ります。

### Customer Gateway（CGW）── 相手の情報を登録する

AWS では「Customer Gateway」というリソースで、接続相手の情報を登録します。GCP の HA VPN は IP を 2 つ持つので、CGW も 2 つ作ります。

```hcl
# terraform/aws/modules/vpn/main.tf
# GCP interface0 に対応する CGW
resource "aws_customer_gateway" "gcp_interface0" {
  bgp_asn    = 65534                    # ← GCP 側の ASN（Step 5 で詳しく説明）
  ip_address = var.gcp_vpn_gateway_ip0  # ← Step 2 で払い出された GCP の IP
  type       = "ipsec.1"
}

# GCP interface1 に対応する CGW
resource "aws_customer_gateway" "gcp_interface1" {
  bgp_asn    = 65534
  ip_address = var.gcp_vpn_gateway_ip1  # ← Step 2 で払い出された GCP の IP
  type       = "ipsec.1"
}
```

`bgp_asn = 65534` は「相手（GCP）の ASN」です。Step 5 で GCP 側の Cloud Router に設定する値と一致させます。

### VPN Connection ── 暗号化トンネルを作る

Customer Gateway（相手の情報）と VPN Gateway（自分の出入口）を紐づけて、VPN Connection を作ります。これがトンネルの実体です。

```hcl
# terraform/aws/modules/vpn/main.tf
resource "aws_vpn_connection" "tunnel0" {
  vpn_gateway_id      = aws_vpn_gateway.main.id                    # Step 1 で作った VGW
  customer_gateway_id = aws_customer_gateway.gcp_interface0[0].id  # 上で作った CGW
  type                = "ipsec.1"
  static_routes_only  = false  # BGP 動的ルーティングを使う（Step 5 で説明）

  # 事前共有鍵（PSK）── GCP 側と同じ値を設定する
  tunnel1_preshared_key = var.tunnel1_preshared_key
  tunnel2_preshared_key = var.tunnel2_preshared_key

  # 暗号化設定
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_dh_group_numbers      = [14]
  # tunnel2 も同様の設定
}

# GCP interface1 向けの VPN Connection も同様に作成
resource "aws_vpn_connection" "tunnel1" {
  vpn_gateway_id      = aws_vpn_gateway.main.id
  customer_gateway_id = aws_customer_gateway.gcp_interface1[0].id
  # ... 暗号化設定は同様
}
```

**VPN Connection を作ると、AWS 側のトンネル用外部 IP が払い出されます。** 1 つの VPN Connection につきトンネルが 2 本あるので、VPN Connection 2 つで合計 4 つの IP が確定します。

```
AWS VPN Connection 0 → tunnel1_address: 52.x.x.1, tunnel2_address: 52.x.x.2
AWS VPN Connection 1 → tunnel1_address: 52.x.x.3, tunnel2_address: 52.x.x.4
```

**この 4 つの IP が、次の Step 4 で GCP 側に渡す情報になります。**

### 暗号化のパラメータ

VPN Connection に設定する暗号化パラメータは、GCP 側と揃える必要があります。

| パラメータ | 設定値 | 説明 |
|-----------|-------|------|
| IKE バージョン | IKEv2 | 鍵交換プロトコル。v2 が推奨 |
| Phase 1 暗号化 | AES-256 | IKE SA の暗号化アルゴリズム |
| Phase 1 整合性 | SHA2-256 | IKE SA の整合性チェック |
| Phase 2 暗号化 | AES-256 | IPsec SA（実データ）の暗号化 |
| Phase 2 整合性 | SHA2-256 | IPsec SA の整合性チェック |
| DH グループ | 14 | Diffie-Hellman 鍵交換のグループ |
| 認証方式 | Pre-Shared Key | 事前共有鍵。AWS と GCP で同じ値を設定 |

**PSK（事前共有鍵）は AWS と GCP で完全に一致させる必要があります。** 1 文字でも違うとトンネルが UP になりません。

## Step 4: GCP 側に External VPN Gateway とトンネルを作る【相手の情報登録 + IPsec トンネル】

AWS のトンネル用 IP が 4 つ確定したので、GCP 側に「相手先（AWS）の情報」を登録し、トンネルを張ります。

### External VPN Gateway ── AWS の情報を登録する

GCP では「External VPN Gateway」で、接続相手（AWS）のトンネル用 IP を登録します。

```hcl
# terraform/gcp/modules/vpn/main.tf
resource "google_compute_external_vpn_gateway" "aws" {
  name            = "poc-dev-aws-vpn-gw"
  redundancy_type = "FOUR_IPS_REDUNDANCY"

  # Step 3 で払い出された AWS の 4 つのトンネル用 IP
  interface {
    id         = 0
    ip_address = var.aws_tunnel0_tunnel1_address  # VPN Connection 0 の tunnel1
  }
  interface {
    id         = 1
    ip_address = var.aws_tunnel0_tunnel2_address  # VPN Connection 0 の tunnel2
  }
  interface {
    id         = 2
    ip_address = var.aws_tunnel1_tunnel1_address  # VPN Connection 1 の tunnel1
  }
  interface {
    id         = 3
    ip_address = var.aws_tunnel1_tunnel2_address  # VPN Connection 1 の tunnel2
  }
}
```

### VPN Tunnel × 4 ── 暗号化トンネルを張る

GCP の 2 つのインターフェースと AWS の 4 つのトンネルアドレスを組み合わせて、4 本のトンネルを張ります。

```hcl
# terraform/gcp/modules/vpn/main.tf
resource "google_compute_vpn_tunnel" "tunnel1" {
  name                            = "poc-dev-tunnel1"
  vpn_gateway                     = google_compute_ha_vpn_gateway.main.id       # Step 2 の GW
  vpn_gateway_interface           = 0                                           # GCP interface0
  peer_external_gateway           = google_compute_external_vpn_gateway.aws[0].id  # 上で作った External GW
  peer_external_gateway_interface = 0                                           # AWS の tunnel0-tunnel1
  shared_secret                   = var.tunnel1_preshared_key  # ← Step 3 の PSK と同じ値
  router                          = google_compute_router.main.id  # Step 5 で作る Router
  ike_version                     = 2
}
# tunnel2: GCP interface0 → AWS tunnel0-tunnel2
# tunnel3: GCP interface1 → AWS tunnel1-tunnel1
# tunnel4: GCP interface1 → AWS tunnel1-tunnel2
# （同様の構成で計 4 本作成）
```

4 本のトンネルの対応関係はこうなります:

```
GCP interface0 ──→ AWS VPN Connection 0 の tunnel1  ... tunnel1
GCP interface0 ──→ AWS VPN Connection 0 の tunnel2  ... tunnel2
GCP interface1 ──→ AWS VPN Connection 1 の tunnel1  ... tunnel3
GCP interface1 ──→ AWS VPN Connection 1 の tunnel2  ... tunnel4
```

4 本すべてが冗長構成で、どれか 1 本でも生きていれば通信は継続します。

**ここまでで、暗号化されたトンネル自体は張れました。** しかし、まだ通信はできません。「どの IP 宛のパケットをこのトンネルに流すか」が決まっていないからです。それを次の Step 5 で設定します。

## Step 5: BGP ルーティングを設定する【BGP ルーティング】

トンネルが張れても、「どの IP 宛のパケットをこのトンネルに流すか」をお互いに教え合わないと、実際のパケットは流れません。「10.0.0.0/16（AWS）宛のパケットはトンネルに流す」「10.1.0.0/24（GCP）宛のパケットはトンネルに流す」という経路情報を交換する必要があります。

これを自動でやるのが **BGP（Border Gateway Protocol）** です。

### ASN（Autonomous System Number）とは

BGP では、各ネットワークを「AS（自律システム）」として識別します。AS ごとに一意の番号（ASN）を割り当て、「自分は ASN 64512 で、10.0.0.0/16 を持っている」と相手に広告します。

| 側 | ASN | 設定箇所 |
|----|-----|---------|
| AWS | 64512 | Step 1 の VPN Gateway（`amazon_side_asn`） |
| GCP | 65534 | Cloud Router（`bgp.asn`） |

ASN はプライベート範囲（64512〜65534）から選びます。**AWS と GCP で異なる番号にする**のがルールです（同じ ASN だと BGP セッションが張れません）。

そして、お互いの ASN を「相手の番号」として登録しています:
- Step 3 の Customer Gateway: `bgp_asn = 65534`（GCP の ASN を登録）
- この Step の BGP Peer: `peer_asn = 64512`（AWS の ASN を登録）

### Cloud Router ── GCP 側の BGP を担当するルーター

GCP では Cloud Router が BGP を担当します。

```hcl
# terraform/gcp/modules/vpn/main.tf
resource "google_compute_router" "main" {
  name    = "poc-dev-router"
  network = var.network_self_link  # VPC にアタッチ

  bgp {
    asn = 65534  # ← GCP 側の ASN
  }
}
```

AWS 側は VPN Gateway に BGP 機能が内蔵されているので、別途ルーターを作る必要はありません。

### BGP セッション用の inside IP

BGP セッションを張るには、トンネルの「内側」で使う専用の IP アドレスが必要です。`169.254.x.x/30` のリンクローカルアドレスを使います。

```
/30 のアドレス空間（4 IP のうち使えるのは 2 つ）:
  169.254.202.0/30
    .0 = ネットワークアドレス（使えない）
    .1 = AWS 側の inside IP
    .2 = GCP 側の inside IP
    .3 = ブロードキャスト（使えない）
```

この inside CIDR は、Step 3 で AWS の VPN Connection を作った時に各トンネルに自動的に割り当てられます。その値を GCP 側に渡して、Cloud Router の Interface と BGP Peer に設定します。

```hcl
# terraform/gcp/modules/vpn/main.tf
# Cloud Router のインターフェース（GCP 側の inside IP を設定）
resource "google_compute_router_interface" "tunnel1" {
  vpn_tunnel = google_compute_vpn_tunnel.tunnel1[0].name
  router     = google_compute_router.main.name
  # /30 の .2 が GCP 側
  ip_range   = "${cidrhost(var.tunnel1_inside_cidr, 2)}/${split("/", var.tunnel1_inside_cidr)[1]}"
}

# BGP ピア（AWS 側の inside IP と ASN を設定）
resource "google_compute_router_peer" "tunnel1" {
  router          = google_compute_router.main.name
  peer_asn        = 64512  # ← AWS の ASN
  interface       = google_compute_router_interface.tunnel1[0].name
  # /30 の .1 が AWS 側
  peer_ip_address = cidrhost(var.tunnel1_inside_cidr, 1)
}
```

各トンネル（4 本）に対して、Router Interface + BGP Peer を 1 セットずつ作ります。

### BGP が確立すると何が起きるか

BGP セッションが確立すると、以下の経路交換が自動的に行われます:

```
AWS (ASN 64512) → GCP に広告: 「10.0.0.0/16 は自分の先にあるよ」
GCP (ASN 65534) → AWS に広告: 「10.1.0.0/24 は自分の先にあるよ」
```

これにより:
- GCP VPC 内で `10.0.0.0/16` 宛のパケット → VPN トンネルへ
- AWS VPC 内で `10.1.0.0/24` 宛のパケット → VPN トンネルへ

と自動的にルーティングされるようになります。

## Step 6: AWS 側のルートテーブルに経路を反映する【ルートテーブル反映】

GCP 側は Cloud Router が BGP で受け取った経路を VPC のルーティングに自動反映してくれるので、追加の設定は不要です。

一方、AWS 側は「VPN Gateway Route Propagation」を明示的に有効にする必要があります。これを設定すると、BGP で受け取った経路がルートテーブルに自動追加されます。

```hcl
# terraform/aws/modules/vpc/main.tf
resource "aws_vpn_gateway_route_propagation" "private" {
  vpn_gateway_id = aws_vpn_gateway.main.id      # Step 1 の VGW
  route_table_id = aws_route_table.private.id    # Aurora があるプライベートサブネットのルートテーブル
}
```

これにより、プライベートサブネットのルートテーブルに以下の経路が自動で追加されます:

```
送信先: 10.1.0.0/24 → ターゲット: vgw-xxxxxxxx（VPN Gateway）
```

手動で `route` ブロックを書く必要はありません。

**ここまでで、VPN 接続は完成です。** GCP VPC 内のパケットが AWS のプライベートサブネットに到達できるようになりました。

## 通信が成立するまでの全体の流れ

Step 1〜6 がすべて揃うと、パケットは以下のように流れます。

```
Cloud Run (10.1.0.x)
  │
  │  Direct VPC Egress で VPC に出る
  ▼
GCP VPC (10.1.0.0/24)
  │
  │  Cloud Router の経路: 10.0.0.0/16 → VPN トンネルへ
  │  （Step 5 の BGP で学習した経路）
  ▼
GCP HA VPN Gateway (34.x.x.x)
  │
  │  IPsec トンネル（IKEv2 / AES-256 / PSK で暗号化）
  │  inside IP: 169.254.x.2 (GCP) ↔ 169.254.x.1 (AWS)
  ▼
AWS VPN Gateway (VGW)
  │
  │  ルート伝播: 10.1.0.0/24 → VPN Gateway
  │  （Step 6 で有効化した経路）
  ▼
AWS プライベートサブネット (10.0.10.0/24)
  │
  │  Security Group: 10.1.0.0/16 からの 3306 を許可
  ▼
Aurora Serverless v2 (MySQL 8.0)
```

## Terraform での段階的 apply

ここまでの Step 1〜6 を Terraform で構築する場合、IP アドレスの循環依存があるため 1 回の apply では完結しません。`count` を使って「IP が未確定の間はリソースを作らない」という制御を行い、段階的に apply します。

```
[1回目] AWS apply
  → Step 1: VPN Gateway を作成
  → Step 3 の CGW / VPN Connection は GCP IP 未確定のためスキップ

[2回目] GCP apply
  → Step 2: HA VPN Gateway を作成 → 外部 IP 2 つが確定
  → Step 4 のトンネルは AWS IP 未確定のためスキップ

[3回目] AWS re-apply（GCP の IP を tfvars に設定）
  → Step 3: CGW × 2 + VPN Connection × 2 を作成
  → トンネル用 IP 4 つ + inside CIDR が確定

[4回目] GCP re-apply（AWS の IP を tfvars に設定）
  → Step 4: External VPN GW + トンネル × 4 を作成
  → Step 5: Cloud Router + BGP を作成
  → VPN トンネル UP、BGP セッション確立
```

### count による条件付き作成

```hcl
# terraform/aws/modules/vpn/main.tf
# AWS 側: GCP の IP が 0.0.0.0（デフォルト = 未確定）の間は作らない
locals {
  vpn_ready = var.gcp_vpn_gateway_ip0 != "0.0.0.0"
}
resource "aws_customer_gateway" "gcp_interface0" {
  count = local.vpn_ready ? 1 : 0
  # ...
}

# terraform/gcp/modules/vpn/main.tf
# GCP 側: AWS のアドレスが空（デフォルト = 未確定）の間は作らない
locals {
  tunnels_ready = var.aws_tunnel0_tunnel1_address != ""
}
resource "google_compute_vpn_tunnel" "tunnel1" {
  count = local.tunnels_ready ? 1 : 0
  # ...
}
```

変数のデフォルト値を「未確定を表す値」（`0.0.0.0` や空文字）にしておき、相手側の apply 後に実際の値で tfvars を上書きする、というパターンです。

## 要素の対応表

| 構築順 | やること | AWS のリソース | GCP のリソース |
|-------|---------|---------------|---------------|
| Step 1 | VPN の出入口を作る | `aws_vpn_gateway` | - |
| Step 2 | VPN の出入口を作る（IP 払い出し） | - | `google_compute_ha_vpn_gateway` |
| Step 3 | 相手の情報登録 + トンネル作成（IP 払い出し） | `aws_customer_gateway` × 2 + `aws_vpn_connection` × 2 | - |
| Step 4 | 相手の情報登録 + トンネル作成 | - | `google_compute_external_vpn_gateway` + `google_compute_vpn_tunnel` × 4 |
| Step 5 | BGP ルーティング | VGW 内蔵（自動） | `google_compute_router` + `router_interface` + `router_peer` |
| Step 6 | ルートテーブルへの経路反映 | `aws_vpn_gateway_route_propagation` | Cloud Router が自動反映 |

| 設定値 | AWS 側 | GCP 側 | 一致が必要 |
|-------|--------|--------|-----------|
| ASN | `amazon_side_asn = 64512` | `bgp { asn = 65534 }` | 異なる値にする |
| 相手の ASN | CGW の `bgp_asn = 65534` | Peer の `peer_asn = 64512` | 相手の値と一致 |
| PSK | `tunnel1_preshared_key` | `shared_secret` | 完全一致 |
| inside IP | VPN Connection 作成時に自動生成 | Router Interface の `ip_range` に手動設定 | AWS の値を GCP に転記 |
| 暗号化 | VPN Connection の tunnel 設定 | VPN Tunnel の `ike_version` | パラメータを揃える |

## おわりに

AWS ↔ GCP の VPN 接続は、構築順に追うと以下の流れです:

1. 両側に VPN Gateway を作る（GCP 側で外部 IP が払い出される）
2. GCP の IP を AWS に渡して、Customer Gateway + VPN Connection を作る（AWS 側でトンネル用 IP が払い出される）
3. AWS の IP を GCP に渡して、External VPN Gateway + トンネルを作る
4. Cloud Router で BGP を設定し、inside IP と ASN を使って経路情報を自動交換する
5. AWS 側のルートテーブルに VPN の経路を伝播させる

つまずきやすいポイントは 3 つ:
- **ASN**: AWS と GCP で異なる番号を設定し、相手の ASN をピアとして登録する
- **PSK**: AWS の VPN Connection と GCP の VPN Tunnel で完全に同じ値にする
- **inside IP**: AWS が自動生成した `/30` の `.1` と `.2` を、GCP の Router Interface と BGP Peer に正しく設定する

これらを間違えなければ、VPN は繋がります。
