package middleware

//这段代码实现了一个用于处理跨域请求的 Gin 框架中间件。
//它的主要目的是让运行在不同域名、端口或协议下的前端应用
//（例如 http://localhost:3000）能够安全地访问你的 Gin 后端 API（例如 http://localhost:8080），
// 从而解决浏览器同源策略的限制

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

func Cors() gin.HandlerFunc {
	return func(c *gin.Context) {
		c.Writer.Header().Set("Access-Control-Allow-Origin", "*")
		c.Writer.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Writer.Header().Set("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}

// 添加白名单机制，只允许特定域名访问API
// allowedOrigins := map[string]bool{
//     "https://your-trusted-site.com": true,
//     "https://admin.your-app.com":    true,
// }

// origin := c.Request.Header.Get("Origin")
// if allowedOrigins[origin] {
//     c.Writer.Header().Set("Access-Control-Allow-Origin", origin)
// }
// 或者使用配置更灵活的第三方库，如 `github.com/gin-contrib/cors`[5,7](@ref)
