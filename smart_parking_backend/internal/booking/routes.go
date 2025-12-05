package booking

import "github.com/gin-gonic/gin"

// RegisterRoutes 注册 booking 模块相关路由
func BookingRoutes(r *gin.Engine, service *Service) {
	handler := NewHandler(service)

	api := r.Group("/api/v4/booking")
	{
		api.POST("/create", handler.CreateBooking)                        // 创建预订
		api.DELETE("/cancel/:id", handler.CancelBooking)                  // 取消预订
		api.GET("/user", handler.GetUserBookings)                         // 获取用户预订列表
		api.GET("/detail/:id", handler.GetBookingDetail)                  // 获取预订详情
		api.POST("/check-expired", handler.CheckAndUpdateExpiredBookings) // 检查并更新超时预订
	}
}
