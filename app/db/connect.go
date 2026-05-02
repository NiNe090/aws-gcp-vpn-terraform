package db

import (
	"database/sql"
	"fmt"
	"log"
	"time"

	_ "github.com/go-sql-driver/mysql"

	"github.com/poc/multicloud-app/secret"
)

// Connect は Aurora に接続し *sql.DB を返す。
// Aurora コールドスタートを考慮して最大 3 回リトライする。
func Connect(cfg *secret.DBConfig) (*sql.DB, error) {
	dsn := fmt.Sprintf(
		"%s:%s@tcp(%s:%d)/%s?parseTime=true&timeout=60s&readTimeout=60s&writeTimeout=60s",
		cfg.User, cfg.Password, cfg.Host, cfg.Port, cfg.DBName,
	)

	db, err := sql.Open("mysql", dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to open db: %w", err)
	}

	db.SetMaxOpenConns(5)
	db.SetMaxIdleConns(2)
	db.SetConnMaxLifetime(30 * time.Minute)

	// 指数バックオフでリトライ（1s → 2s → 4s）
	const maxRetries = 3
	wait := time.Second
	for i := 1; i <= maxRetries; i++ {
		if err = db.Ping(); err == nil {
			log.Printf("db: connected to Aurora (attempt %d)", i)
			return db, nil
		}
		log.Printf("db: ping failed (attempt %d/%d): %v", i, maxRetries, err)
		if i < maxRetries {
			time.Sleep(wait)
			wait *= 2
		}
	}

	return nil, fmt.Errorf("failed to connect to Aurora after %d attempts: %w", maxRetries, err)
}
