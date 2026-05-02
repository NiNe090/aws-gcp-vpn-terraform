# ── ビルドステージ ──────────────────────────────────────────────
FROM golang:1.22-alpine AS builder

WORKDIR /app

# 依存関係を先にコピーしてキャッシュを活用
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO 無効で静的リンクバイナリを生成
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -o server .

# ── 実行ステージ ────────────────────────────────────────────────
FROM alpine:3.19

# CA 証明書（Secret Manager / Aurora の TLS 接続に必要）
RUN apk --no-cache add ca-certificates

# 非 root ユーザーで実行
RUN adduser -D -u 1000 appuser
USER appuser

WORKDIR /app
COPY --from=builder /app/server .

EXPOSE 8080
CMD ["./server"]
