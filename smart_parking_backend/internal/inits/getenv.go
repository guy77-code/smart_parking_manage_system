package inits

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

// GetEnv 获取环境变量，支持.env文件
func GetEnv(key string) string {
	// 尝试加载.env文件
	err := godotenv.Load()
	if err != nil {
		log.Println("Warning: Error loading .env file, using system environment")
	}

	// 获取环境变量
	value := os.Getenv(key)
	if value == "" {
		log.Printf("Warning: Environment variable %s is not set\n", key)
	}
	return value
}

// GetEnvWithDefault 获取环境变量，提供默认值
func GetEnvWithDefault(key, defaultValue string) string {
	value := GetEnv(key)
	if value == "" {
		return defaultValue
	}
	return value
}
