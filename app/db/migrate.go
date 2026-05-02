package db

import (
	"database/sql"
	"fmt"
	"log"
)

// Migrate は items テーブルを作成し、シードデータを投入する。
// CREATE TABLE IF NOT EXISTS / INSERT IGNORE により冪等に実行できる。
func Migrate(db *sql.DB) error {
	if err := createTable(db); err != nil {
		return err
	}
	return seedData(db)
}

func createTable(db *sql.DB) error {
	query := `
CREATE TABLE IF NOT EXISTS items (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(255) NOT NULL UNIQUE,
  value      VARCHAR(255),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
)`
	if _, err := db.Exec(query); err != nil {
		return fmt.Errorf("migrate: failed to create items table: %w", err)
	}
	log.Println("migrate: items table ready")
	return nil
}

func seedData(db *sql.DB) error {
	seeds := []struct{ name, value string }{
		{"item-1", "hello from Aurora"},
		{"item-2", "multicloud connection test"},
		{"item-3", "GCP CloudRun -> AWS Aurora"},
	}

	for _, s := range seeds {
		// INSERT IGNORE: name が既に存在する場合はスキップ（冪等）
		// name カラムに UNIQUE 制約が必要なため、追加する
		_, err := db.Exec(
			`INSERT IGNORE INTO items (name, value) VALUES (?, ?)`,
			s.name, s.value,
		)
		if err != nil {
			return fmt.Errorf("migrate: failed to seed item %q: %w", s.name, err)
		}
	}
	log.Println("migrate: seed data ready")
	return nil
}
