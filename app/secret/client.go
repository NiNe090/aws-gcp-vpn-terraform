package secret

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

	secretmanager "cloud.google.com/go/secretmanager/apiv1"
	"cloud.google.com/go/secretmanager/apiv1/secretmanagerpb"
)

// DBConfig は GCP Secret Manager から取得する Aurora 接続情報
type DBConfig struct {
	Host     string `json:"host"`
	Port     int    `json:"port"`
	User     string `json:"user"`
	Password string `json:"password"`
	DBName   string `json:"dbname"`
}

// GetConfig は環境変数 SECRET_NAME と GOOGLE_CLOUD_PROJECT を使って
// GCP Secret Manager から Aurora 接続情報を取得する
func GetConfig(ctx context.Context) (*DBConfig, error) {
	secretName := os.Getenv("SECRET_NAME")
	if secretName == "" {
		return nil, fmt.Errorf("SECRET_NAME environment variable is not set")
	}

	projectID := os.Getenv("GOOGLE_CLOUD_PROJECT")
	if projectID == "" {
		return nil, fmt.Errorf("GOOGLE_CLOUD_PROJECT environment variable is not set")
	}

	client, err := secretmanager.NewClient(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to create secret manager client: %w", err)
	}
	defer client.Close()

	name := fmt.Sprintf("projects/%s/secrets/%s/versions/latest", projectID, secretName)
	req := &secretmanagerpb.AccessSecretVersionRequest{Name: name}

	result, err := client.AccessSecretVersion(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to access secret %s: %w", name, err)
	}

	if result.Payload == nil || result.Payload.Data == nil {
		return nil, fmt.Errorf("secret %s has empty payload", name)
	}

	var cfg DBConfig
	if err := json.Unmarshal(result.Payload.Data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to parse secret JSON: %w", err)
	}

	return &cfg, nil
}
