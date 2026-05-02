package handlers

import (
	"database/sql"
	"net/http"
	"time"
)

// DBHandler は *sql.DB を保持し、DB 関連エンドポイントを提供する。
type DBHandler struct {
	DB *sql.DB
}

// Item は items テーブルの 1 行を表す。
type Item struct {
	ID        int       `json:"id"`
	Name      string    `json:"name"`
	Value     string    `json:"value"`
	CreatedAt time.Time `json:"created_at"`
}

// Ping は GET /db/ping のハンドラー。SELECT 1 でレイテンシを計測する。
func (h *DBHandler) Ping(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	_, err := h.DB.ExecContext(r.Context(), "SELECT 1")
	latency := time.Since(start).Milliseconds()

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"status":     "error",
			"latency_ms": latency,
			"message":    err.Error(),
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"status":     "ok",
		"latency_ms": latency,
		"message":    "Aurora connection successful",
	})
}

// Version は GET /db/version のハンドラー。Aurora のバージョン文字列を返す。
func (h *DBHandler) Version(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	var version string
	err := h.DB.QueryRowContext(r.Context(), "SELECT VERSION()").Scan(&version)
	latency := time.Since(start).Milliseconds()

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"status":     "error",
			"latency_ms": latency,
			"message":    err.Error(),
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"status":     "ok",
		"latency_ms": latency,
		"version":    version,
	})
}

// Query は GET /db/query のハンドラー。items テーブルの全件を返す。
func (h *DBHandler) Query(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	rows, err := h.DB.QueryContext(r.Context(), "SELECT id, name, value, created_at FROM items")
	latency := time.Since(start).Milliseconds()

	if err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"status":     "error",
			"latency_ms": latency,
			"message":    err.Error(),
			"rows":       nil,
		})
		return
	}
	defer rows.Close()

	var items []Item
	for rows.Next() {
		var item Item
		if err := rows.Scan(&item.ID, &item.Name, &item.Value, &item.CreatedAt); err != nil {
			writeJSON(w, http.StatusInternalServerError, map[string]any{
				"status":     "error",
				"latency_ms": latency,
				"message":    err.Error(),
				"rows":       nil,
			})
			return
		}
		items = append(items, item)
	}
	if err := rows.Err(); err != nil {
		writeJSON(w, http.StatusInternalServerError, map[string]any{
			"status":     "error",
			"latency_ms": latency,
			"message":    err.Error(),
			"rows":       nil,
		})
		return
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"status":     "ok",
		"latency_ms": latency,
		"count":      len(items),
		"rows":       items,
	})
}
