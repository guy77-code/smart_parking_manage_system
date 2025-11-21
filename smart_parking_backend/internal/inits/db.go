package inits

import (
	"fmt"
	"log"
	"os"
	"time"

	"gopkg.in/yaml.v3"
	"gorm.io/driver/mysql"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

var DB *gorm.DB

type Config struct {
	Database struct {
		Host      string `yaml:"host"`
		Port      int    `yaml:"port"`
		User      string `yaml:"user"`
		Password  string `yaml:"password"`
		Name      string `yaml:"name"`
		Charset   string `yaml:"charset"`
		ParseTime bool   `yaml:"parseTime"`
		Loc       string `yaml:"loc"`
		MaxOpen   int    `yaml:"maxOpen"` // 最大打开连接数
		MaxIdle   int    `yaml:"maxIdle"` // 最大空闲连接数
		MaxLife   int    `yaml:"maxLife"` // 连接最大生命周期（分钟）
	} `yaml:"database"`
}

func InitDB() {
	yamlFile, err := os.ReadFile("config/config.yaml")
	if err != nil {
		log.Fatalf("❌ Failed to read config file: %v", err)
	}

	var cfg Config
	if err := yaml.Unmarshal(yamlFile, &cfg); err != nil {
		log.Fatalf("❌ Failed to parse config file: %v", err)
	}

	dsn := fmt.Sprintf("%s:%s@tcp(%s:%d)/%s?charset=%s&parseTime=%t&loc=%s",
		cfg.Database.User,
		cfg.Database.Password,
		cfg.Database.Host,
		cfg.Database.Port,
		cfg.Database.Name,
		cfg.Database.Charset,
		cfg.Database.ParseTime,
		cfg.Database.Loc,
	)

	// 自定义GORM日志与配置
	DB, err = gorm.Open(mysql.Open(dsn), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Warn), // 仅警告级别日志
	})
	if err != nil {
		log.Fatalf("❌ Failed to connect to MySQL: %v", err)
	}

	sqlDB, err := DB.DB()
	if err != nil {
		log.Fatalf("❌ 获取底层数据库连接失败: %v", err)
	}

	// ✅ 连接池配置
	sqlDB.SetMaxOpenConns(cfg.Database.MaxOpen)                                 // 最大打开连接数（推荐 100~500）
	sqlDB.SetMaxIdleConns(cfg.Database.MaxIdle)                                 // 最大空闲连接数（推荐 50~200）
	sqlDB.SetConnMaxLifetime(time.Duration(cfg.Database.MaxLife) * time.Minute) // 单连接生命周期

	fmt.Println("✅ 数据库连接池初始化完成，支持高并发访问")
}
