#!/usr/bin/env bash
# deploy.sh: アプリコンテナのビルド・Artifact Registry への push・Cloud Run デプロイを行う
#
# 使い方:
#   bash scripts/deploy.sh <REPO_URL> <TAG>
#
# 引数:
#   REPO_URL  Artifact Registry リポジトリ URL
#             (例: us-central1-docker.pkg.dev/my-project/poc-dev-app)
#   TAG       イメージタグ (例: v1.0.0)
#
# 実行前提条件:
#   - Docker が起動していること
#   - gcloud CLI がインストール・認証済みであること
#     (gcloud auth configure-docker <REGION>-docker.pkg.dev)
#   - terraform/gcp で apply 済みで Artifact Registry が存在すること

set -euo pipefail

# ─── 引数チェック ─────────────────────────────────────────────────
if [[ $# -lt 2 ]]; then
  echo "Usage: bash scripts/deploy.sh <REPO_URL> <TAG>" >&2
  echo "  REPO_URL: e.g. us-central1-docker.pkg.dev/my-project/poc-dev-app" >&2
  echo "  TAG:      e.g. v1.0.0" >&2
  exit 1
fi

REPO_URL="$1"
TAG="$2"
# Artifact Registry の形式: HOST/PROJECT/REPOSITORY/IMAGE:TAG
IMAGE_URL="${REPO_URL}/app:${TAG}"

# スクリプトのあるディレクトリからプロジェクトルートを特定
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
APP_DIR="${PROJECT_ROOT}/app"

echo "=== Deploy Start ==="
echo "  Image: ${IMAGE_URL}"
echo "  App dir: ${APP_DIR}"

# ─── Artifact Registry 認証 ───────────────────────────────────────
# REPO_URL から <region>-docker.pkg.dev を抽出して configure-docker を実行
REGISTRY_HOST="$(echo "${REPO_URL}" | cut -d'/' -f1)"
echo ""
echo "[1/4] Configuring Docker auth for ${REGISTRY_HOST} ..."
gcloud auth configure-docker "${REGISTRY_HOST}" --quiet

# ─── Docker ビルド ────────────────────────────────────────────────
echo ""
echo "[2/4] Building Docker image ..."
docker build \
  --platform linux/amd64 \
  -t "${IMAGE_URL}" \
  "${APP_DIR}"

# ─── Artifact Registry への push ─────────────────────────────────
echo ""
echo "[3/4] Pushing image to Artifact Registry ..."
docker push "${IMAGE_URL}"

echo ""
echo "[4/4] Done."
echo ""
echo "Next step: Update terraform/gcp/terraform.tfvars"
echo "  app_image_url = \"${IMAGE_URL}\""
echo ""
echo "Then re-apply GCP Terraform:"
echo "  cd terraform/gcp && terraform apply"
