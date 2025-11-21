package inits

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"gopkg.in/yaml.v3"

	"github.com/redis/go-redis/v9"
)

// RedisClient 仍然导出以兼容现有代码，但推荐使用 InitRedis 返回的 client 或者调用 GetRedisClient()
var RedisClient *redis.Client
var Ctx = context.Background()

// RedisConfig 定义配置文件结构，用于解析YAML格式的Redis配置
type RedisConfig struct {
	Redis struct {
		Addr     string `yaml:"addr"`     // Redis服务器地址和端口，格式为"host:port"
		Password string `yaml:"password"` // Redis认证密码，如果没有密码则为空
		DB       int    `yaml:"db"`       // 选择的Redis数据库编号，默认为0
	} `yaml:"redis"` // YAML标签，对应配置文件中的redis层级
}

// InitRedis 从配置文件初始化redis客户端并返回该客户端与可能的错误
// ctx 用于ping的超时/取消控制；如果传入nil，将使用2秒的默认超时
// path 是配置文件路径（例如"config/config.yaml"）
func InitRedis(ctx context.Context, path string) (*redis.Client, error) {
	// 参数校验：确保配置文件路径不为空
	if path == "" {
		return nil, errors.New("config path is required")
	}

	// 读取YAML配置文件内容
	yamlFile, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("read config file: %w", err)
	}

	// 解析YAML配置文件到RedisConfig结构体
	var cfg RedisConfig
	if err := yaml.Unmarshal(yamlFile, &cfg); err != nil {
		return nil, fmt.Errorf("parse config file: %w", err)
	}

	// 校验Redis地址配置是否为空
	if cfg.Redis.Addr == "" {
		return nil, errors.New("redis.addr is empty in config")
	}

	// 创建Redis客户端实例,为每个连接创建 redisClient结构体。
	client := redis.NewClient(&redis.Options{
		Addr:         cfg.Redis.Addr,     // Redis服务器地址
		Password:     cfg.Redis.Password, // 认证密码
		DB:           cfg.Redis.DB,       // 数据库编号
		PoolSize:     700,                // 最大连接数（匹配MySQL连接池）
		MinIdleConns: 100,                // 最小空闲连接
		DialTimeout:  3 * time.Second,    // 建立连接超时
		ReadTimeout:  2 * time.Second,    // 读超时
		WriteTimeout: 2 * time.Second,    // 写超时
		PoolTimeout:  4 * time.Second,    // 等待连接超时
	})

	// 使用带超时的ctx进行Ping验证，避免长时间阻塞
	pingCtx := ctx
	var cancel context.CancelFunc

	// 如果传入的ctx为nil，创建带有2秒超时的默认context
	if pingCtx == nil {
		pingCtx, cancel = context.WithTimeout(context.Background(), 2*time.Second)
	} else {
		// 如果调用者提供的ctx没有截止时间，添加一个默认超时
		if _, ok := pingCtx.Deadline(); !ok {
			pingCtx, cancel = context.WithTimeout(pingCtx, 2*time.Second)
		}
	}
	// 确保在函数返回前取消context，释放资源
	if cancel != nil {
		defer cancel()
	}

	// 使用Ping命令测试Redis连接是否正常
	if err := client.Ping(pingCtx).Err(); err != nil {
		_ = client.Close() // 如果连接测试失败，关闭客户端
		return nil, fmt.Errorf("ping redis: %w", err)
	}

	// 将客户端赋值到包级变量以保持向后兼容
	RedisClient = client
	return client, nil
}

// CloseRedis 关闭导出的RedisClient（如果存在）。建议调用方使用返回的client并显式关闭
func CloseRedis() error {
	if RedisClient == nil {
		return nil // 如果客户端未初始化，直接返回nil
	}
	return RedisClient.Close() // 关闭Redis连接，释放资源
}
