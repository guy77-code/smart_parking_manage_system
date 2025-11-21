package payment

import (
	"smart_parking_backend/internal/booking"

	"github.com/gin-gonic/gin"
)

func PaymentRoutes(r *gin.Engine, bookingSvc *booking.Service, cfg *Config) {
	svc := NewService(bookingSvc, cfg)
	handler := NewHandler(svc)

	g := r.Group("/api/payment")
	{
		g.POST("/create", handler.CreatePaymentRedirectHandler)
		g.POST("/notify/alipay", handler.AlipayNotifyHandler)
	}
}
