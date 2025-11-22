package payment

import (
	"smart_parking_backend/internal/booking"

	"github.com/gin-gonic/gin"
)

// PaymentRoutes 注册路由
func PaymentRoutes(r *gin.Engine, bookingSvc *booking.Service, cfg *Config) {
	svc := NewService(bookingSvc, cfg)
	handler := NewHandler(svc)

	g := r.Group("/api/payment")
	{
		g.POST("/create", handler.CreatePaymentRedirectHandler) // 统一创建支付（reservation/parking/violation）
		g.POST("/notify", handler.NotifyHandler)                // 模拟支付回调（前端模拟页面会 POST 到这里）
	}
}
