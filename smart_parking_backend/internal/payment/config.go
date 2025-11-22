package payment

import (
	"os"

	"gopkg.in/yaml.v3"
)

// Config 映射 YAML 配置（保留原有 alipay 字段，便于未来扩展）
type Config struct {
	Alipay struct {
		AppID          string `yaml:"app_id"`
		PrivateKeyPath string `yaml:"private_key_path"`
		PublicKeyPath  string `yaml:"public_key_path"`
		NotifyURL      string `yaml:"notify_url"`
		ReturnURL      string `yaml:"return_url"`
		GatewayURL     string `yaml:"gateway_url"`
		Charset        string `yaml:"charset"`
		SignType       string `yaml:"sign_type"`
	} `yaml:"alipay"`

	// 可选：模拟支付页面的基础地址，前端 QT 可在该地址启动页面（若 YAML 未配置则使用默认）
	SimulateHost string `yaml:"simulate_host"`
}

// LoadSandboxConfig 从 YAML 文件加载配置
func LoadSandboxConfig(path string) (*Config, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, err
	}
	return &cfg, nil
}

// Helper 方法：暴露返回与通知 URL
func (c *Config) AlipayNotifyURL() string {
	return c.Alipay.NotifyURL
}
func (c *Config) AlipayReturnURL() string {
	return c.Alipay.ReturnURL
}
