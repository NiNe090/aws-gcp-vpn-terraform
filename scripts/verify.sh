#!/usr/bin/env bash
# verify.sh: Cloud Run の全エンドポイントに対して動作確認を行う
#
# 使い方:
#   bash scripts/verify.sh <CLOUD_RUN_URL>
#
# 引数:
#   CLOUD_RUN_URL  Cloud Run サービスの URL
#                  (例: https://poc-dev-app-xxxxxxxxxx-uc.a.run.app)
#
# 実行前提条件:
#   - curl がインストールされていること
#   - gcloud CLI がインストール・認証済みであること（Bearer トークン取得に使用）
#   - Cloud Run に allUsers の権限はないため Identity Token が必要

set -euo pipefail

# ─── 引数チェック ─────────────────────────────────────────────────
if [[ $# -lt 1 ]]; then
  echo "Usage: bash scripts/verify.sh <CLOUD_RUN_URL>" >&2
  echo "  CLOUD_RUN_URL: e.g. https://poc-dev-app-xxxxxxxxxx-uc.a.run.app" >&2
  exit 1
fi

BASE_URL="${1%/}"  # 末尾スラッシュを除去

echo "=== Verify Start ==="
echo "  Target: ${BASE_URL}"

# ─── Identity Token 取得 ──────────────────────────────────────────
echo ""
echo "Fetching identity token ..."
ID_TOKEN="$(gcloud auth print-identity-token)"

# ─── ヘルパー関数 ─────────────────────────────────────────────────
check_endpoint() {
  local label="$1"
  local path="$2"
  local expected_status="${3:-200}"

  echo ""
  echo "--- ${label} (${path}) ---"
  HTTP_STATUS=$(curl -s -o /tmp/verify_response.json -w "%{http_code}" \
    -H "Authorization: Bearer ${ID_TOKEN}" \
    "${BASE_URL}${path}")

  if [[ "${HTTP_STATUS}" == "${expected_status}" ]]; then
    echo "  Status: ${HTTP_STATUS} OK"
    cat /tmp/verify_response.json | python3 -m json.tool 2>/dev/null || cat /tmp/verify_response.json
  else
    echo "  Status: ${HTTP_STATUS} (expected ${expected_status})" >&2
    cat /tmp/verify_response.json >&2
    FAILED=$((FAILED + 1))
  fi
}

FAILED=0

# ─── エンドポイント確認 ───────────────────────────────────────────
check_endpoint "Health Check"    "/health"      200
check_endpoint "DB Ping"         "/db/ping"     200
check_endpoint "DB Version"      "/db/version"  200
check_endpoint "DB Query"        "/db/query"    200

# ─── 結果サマリー ────────────────────────────────────────────────
echo ""
echo "==================================="
if [[ "${FAILED}" -eq 0 ]]; then
  echo "All checks PASSED"
else
  echo "${FAILED} check(s) FAILED" >&2
  exit 1
fi
