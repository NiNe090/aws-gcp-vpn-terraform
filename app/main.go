package main

import (
	"context"
	"log"
	"net/http"

	"github.com/poc/multicloud-app/db"
	"github.com/poc/multicloud-app/handlers"
	"github.com/poc/multicloud-app/secret"
)

func main() {
	ctx := context.Background()

	// GCP Secret Manager から Aurora 接続情報を取得
	cfg, err := secret.GetConfig(ctx)
	if err != nil {
		log.Fatalf("failed to get db config: %v", err)
	}

	// Aurora に接続
	sqlDB, err := db.Connect(cfg)
	if err != nil {
		log.Fatalf("failed to connect to Aurora: %v", err)
	}
	defer sqlDB.Close()

	// items テーブル作成 + シードデータ投入（冪等）
	if err := db.Migrate(sqlDB); err != nil {
		log.Fatalf("failed to migrate: %v", err)
	}

	// HTTP ルーティング
	dbHandler := &handlers.DBHandler{DB: sqlDB}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /health", handlers.Health)
	mux.HandleFunc("GET /db/ping", dbHandler.Ping)
	mux.HandleFunc("GET /db/version", dbHandler.Version)
	mux.HandleFunc("GET /db/query", dbHandler.Query)

	log.Println("server: listening on :8080")
	if err := http.ListenAndServe(":8080", mux); err != nil {
		log.Fatalf("server: %v", err)
	}
}
