package utils

import (
	"fmt"
	"math/rand"
	"regexp"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Generate6DigitCode 生成6位随机数字验证码
func Generate6DigitCode() string {
	// 为每次调用创建独立的随机源和生成器
	source := rand.NewSource(time.Now().UnixNano())
	rng := rand.New(source)
	return fmt.Sprintf("%06d", rng.Intn(1000000))
}

var jwtSecret = []byte("your_secret_key_here") // ✅ 请放在安全位置，比如 .env 文件中

// Claims 定义自定义声明
type Claims struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
	jwt.RegisteredClaims
}

// GenerateToken 生成JWT令牌
func GenerateToken(userID uint, username string) (string, error) {
	claims := Claims{
		UserID:   userID,
		Username: username,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)), // token 24小时有效
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			Issuer:    "parking-system", // 令牌签发者
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(jwtSecret)
}

// ParseToken 验证JWT令牌并返回claims
func ParseToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		return jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}

	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims, nil
	}
	return nil, jwt.ErrTokenInvalidClaims
}

// validatePhoneFormat 验证手机号格式（中国大陆11位手机号基本格式）
func ValidatePhoneFormat(phone string) bool {
	pattern := `^1[3-9]\d{9}$`
	re := regexp.MustCompile(pattern)
	return re.MatchString(phone)
}

// ParseInt 安全解析字符串为整数。
// 如果解析失败，则返回默认值 defaultVal。
func ParseInt(s string, defaultVal int) int {
	if s == "" {
		return defaultVal
	}

	// 尝试转换为整数
	if val, err := strconv.Atoi(s); err == nil {
		return val
	}

	// 转换失败时返回默认值
	return defaultVal
}
