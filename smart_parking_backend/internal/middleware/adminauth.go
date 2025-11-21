package middleware

import (
	"net/http"
	"smart_parking_backend/internal/inits"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

func AdminAuthMiddleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		// 获取Authorization头部
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "缺少认证token"})
			c.Abort()
			return
		}

		// 验证Authorization头部格式
		parts := strings.SplitN(authHeader, " ", 2)
		if !(len(parts) == 2 && parts[0] == "Bearer") {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的认证token格式"})
			c.Abort()
			return
		}

		// 解析JWT Token
		tokenStr := parts[1]
		token, err := jwt.Parse(tokenStr, func(token *jwt.Token) (interface{}, error) {
			return []byte(inits.GetEnv("JWT_SECRET_ADMIN")), nil
		})

		if err != nil || !token.Valid {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的token"})
			c.Abort()
			return
		}

		// 提取Claims
		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "无效的token"})
			c.Abort()
			return
		}

		// 存储管理员信息到上下文
		c.Set("admin_id", uint(claims["admin_id"].(float64)))
		c.Set("phone", claims["phone"])
		c.Set("role", claims["role"])

		if claims["lot_id"] != nil {
			c.Set("lot_id", uint(claims["lot_id"].(float64)))
		}

		c.Next()
	}
}
