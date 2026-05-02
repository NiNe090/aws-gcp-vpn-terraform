package handlers_test

import (
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/poc/multicloud-app/handlers"
)

// ─── モック DB ドライバー ────────────────────────────────────────

type mockDriver struct{}
type mockConn struct{}
type mockStmt struct{ query string }
type mockRows struct {
	cols    []string
	data    [][]driver.Value
	current int
}
type mockResult struct{}

func init() {
	sql.Register("mock", &mockDriver{})
}

func (d *mockDriver) Open(name string) (driver.Conn, error) { return &mockConn{}, nil }
func (c *mockConn) Prepare(query string) (driver.Stmt, error) {
	return &mockStmt{query: query}, nil
}
func (c *mockConn) Close() error          { return nil }
func (c *mockConn) Begin() (driver.Tx, error) { return nil, nil }

func (s *mockStmt) Close() error                                    { return nil }
func (s *mockStmt) NumInput() int                                   { return -1 }
func (s *mockStmt) Exec(args []driver.Value) (driver.Result, error) { return &mockResult{}, nil }
func (s *mockStmt) Query(args []driver.Value) (driver.Rows, error) {
	switch s.query {
	case "SELECT 1":
		return &mockRows{cols: []string{"1"}, data: [][]driver.Value{{int64(1)}}}, nil
	case "SELECT VERSION()":
		return &mockRows{cols: []string{"VERSION()"}, data: [][]driver.Value{{"8.0.28"}}}, nil
	case "SELECT id, name, value, created_at FROM items":
		return &mockRows{
			cols: []string{"id", "name", "value", "created_at"},
			data: [][]driver.Value{
				{int64(1), "item-1", "hello from Aurora", "2026-03-29T00:00:00Z"},
				{int64(2), "item-2", "multicloud connection test", "2026-03-29T00:00:00Z"},
				{int64(3), "item-3", "GCP CloudRun -> AWS Aurora", "2026-03-29T00:00:00Z"},
			},
		}, nil
	default:
		return &mockRows{cols: []string{}, data: nil}, nil
	}
}

func (r *mockResult) LastInsertId() (int64, error) { return 0, nil }
func (r *mockResult) RowsAffected() (int64, error) { return 1, nil }

func (r *mockRows) Columns() []string { return r.cols }
func (r *mockRows) Close() error      { return nil }
func (r *mockRows) Next(dest []driver.Value) error {
	if r.current >= len(r.data) {
		return io.EOF
	}
	copy(dest, r.data[r.current])
	r.current++
	return nil
}

func newMockDB(t *testing.T) *sql.DB {
	t.Helper()
	db, err := sql.Open("mock", "mock://test")
	if err != nil {
		t.Fatalf("failed to open mock db: %v", err)
	}
	return db
}

// ─── テスト ────────────────────────────────────────────────────

func TestDBPing(t *testing.T) {
	h := &handlers.DBHandler{DB: newMockDB(t)}
	req := httptest.NewRequest(http.MethodGet, "/db/ping", nil)
	rec := httptest.NewRecorder()

	h.Ping(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rec.Code)
	}

	var body map[string]any
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if body["status"] != "ok" {
		t.Errorf("expected status=ok, got %v", body["status"])
	}
	if _, ok := body["latency_ms"]; !ok {
		t.Error("expected latency_ms in response")
	}
}

func TestDBVersion(t *testing.T) {
	h := &handlers.DBHandler{DB: newMockDB(t)}
	req := httptest.NewRequest(http.MethodGet, "/db/version", nil)
	rec := httptest.NewRecorder()

	h.Version(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rec.Code)
	}

	var body map[string]any
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if body["status"] != "ok" {
		t.Errorf("expected status=ok, got %v", body["status"])
	}
	if body["version"] != "8.0.28" {
		t.Errorf("expected version=8.0.28, got %v", body["version"])
	}
}

func TestDBQuery(t *testing.T) {
	h := &handlers.DBHandler{DB: newMockDB(t)}
	req := httptest.NewRequest(http.MethodGet, "/db/query", nil)
	rec := httptest.NewRecorder()

	h.Query(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected status 200, got %d", rec.Code)
	}

	var body map[string]any
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("failed to decode response: %v", err)
	}
	if body["status"] != "ok" {
		t.Errorf("expected status=ok, got %v", body["status"])
	}

	// モック DB が 3 件返すことを検証（functional-design.md の合格基準）
	count, ok := body["count"].(float64)
	if !ok {
		t.Fatal("expected count in response")
	}
	if int(count) != 3 {
		t.Errorf("expected count=3, got %v", count)
	}

	rows, ok := body["rows"].([]any)
	if !ok {
		t.Fatal("expected rows array in response")
	}
	if len(rows) != 3 {
		t.Errorf("expected 3 rows, got %d", len(rows))
	}
}
