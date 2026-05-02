package db_test

import (
	"database/sql"
	"database/sql/driver"
	"io"
	"testing"

	appdb "github.com/poc/multicloud-app/db"
)

// ─── モック DB ドライバー（migrate テスト用）────────────────────

type migrateDriver struct{}
type migrateConn struct{ execLog []string }
type migrateStmt struct {
	conn  *migrateConn
	query string
}
type migrateRows struct{}
type migrateResult struct{}

func init() {
	sql.Register("migrate-mock", &migrateDriver{})
}

func (d *migrateDriver) Open(name string) (driver.Conn, error) {
	return &migrateConn{}, nil
}

func (c *migrateConn) Prepare(query string) (driver.Stmt, error) {
	return &migrateStmt{conn: c, query: query}, nil
}
func (c *migrateConn) Close() error             { return nil }
func (c *migrateConn) Begin() (driver.Tx, error) { return nil, nil }

func (s *migrateStmt) Close() error  { return nil }
func (s *migrateStmt) NumInput() int { return -1 }
func (s *migrateStmt) Exec(args []driver.Value) (driver.Result, error) {
	s.conn.execLog = append(s.conn.execLog, s.query)
	return &migrateResult{}, nil
}
func (s *migrateStmt) Query(args []driver.Value) (driver.Rows, error) {
	return &migrateRows{}, nil
}

func (r *migrateResult) LastInsertId() (int64, error) { return 1, nil }
func (r *migrateResult) RowsAffected() (int64, error) { return 1, nil }
func (r *migrateRows) Columns() []string              { return nil }
func (r *migrateRows) Close() error                   { return nil }
func (r *migrateRows) Next(dest []driver.Value) error { return io.EOF }

// ─── テスト ────────────────────────────────────────────────────

func TestMigrate_Idempotent(t *testing.T) {
	db, err := sql.Open("migrate-mock", "migrate-mock://test")
	if err != nil {
		t.Fatalf("failed to open mock db: %v", err)
	}
	defer db.Close()

	// 1回目
	if err := appdb.Migrate(db); err != nil {
		t.Fatalf("first migrate failed: %v", err)
	}

	// 2回目（冪等性確認: エラーにならないこと）
	if err := appdb.Migrate(db); err != nil {
		t.Fatalf("second migrate failed: %v", err)
	}
}
