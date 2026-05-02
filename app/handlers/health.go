package handlers

import (
	"encoding/json"
	"log"
	"net/http"
)

// Health は GET /health のハンドラー。DB アクセスなしでアプリ死活を確認する。
func Health(w http.ResponseWriter, r *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// writeJSON はステータスコードと任意の値を JSON レスポンスとして書き込む。
func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("writeJSON: encode error: %v", err)
	}
}
