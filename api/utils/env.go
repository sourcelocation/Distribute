package utils

import (
	"os"

	"github.com/joho/godotenv"
)

func init() {
	_ = godotenv.Load()
}

func Getenv(key, fallback string) string {
	value := os.Getenv(key)
	if len(value) == 0 {
		return fallback
	}
	return value
}
