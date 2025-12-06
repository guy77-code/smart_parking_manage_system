package booking

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"smart_parking_backend/internal/model"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

// 统一的响应结构
type Response struct {
	Code    int         `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// 成功响应辅助函数
func successResponse(data interface{}) *Response {
	return &Response{
		Code:    0,
		Message: "success",
		Data:    data,
	}
}

// 错误响应辅助函数
func errorResponse(code int, message string) *Response {
	return &Response{
		Code:    code,
		Message: message,
		Data:    nil,
	}
}

// parseFlexibleTime 尝试多种时间格式进行解析
// 修复时区问题：解析后的时间统一转换为Asia/Shanghai时区，确保与数据库存储时区一致
func parseFlexibleTime(t string) (time.Time, error) {
	// 加载Asia/Shanghai时区
	loc, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		// 如果加载失败，使用本地时区
		loc = time.Local
	}
	
	// 检查是否是 UTC 时区格式（末尾是 Z）
	isUTC := len(t) > 0 && t[len(t)-1] == 'Z'
	
	layouts := []string{
		"2006-01-02 15:04:05",       // 本地时间格式（前端发送的格式，优先匹配）
		"2006-01-02T15:04:05Z",      // UTC 时区格式
		time.RFC3339,                 // RFC3339 格式（可能包含时区偏移）
		"2006/01/02 15:04:05",       // 本地时区格式（斜杠分隔）
	}

	for _, layout := range layouts {
		if parsed, err := time.Parse(layout, t); err == nil {
			// 统一转换为Asia/Shanghai时区
			// 确保与数据库存储时区一致（数据库连接字符串中的 loc 参数为 Asia/Shanghai）
			// 这样存储到数据库的时间与前端输入的时间一致
			if isUTC || layout == "2006-01-02T15:04:05Z" {
				// 解析为 UTC 时区，转换为Asia/Shanghai时区
				shanghaiTime := parsed.In(loc)
				return shanghaiTime, nil
			}
			// 对于 "2006-01-02 15:04:05" 格式，time.Parse 会解析为 UTC，需要转换为Asia/Shanghai时区
			if layout == "2006-01-02 15:04:05" || layout == "2006/01/02 15:04:05" {
				// 这些格式不包含时区信息，time.Parse 会解析为 UTC，需要转换为Asia/Shanghai时区
				// 使用ParseInLocation直接解析为Asia/Shanghai时区
				shanghaiTime, err := time.ParseInLocation("2006-01-02 15:04:05", t, loc)
				if err != nil {
					// 如果解析失败，尝试其他格式
					shanghaiTime = parsed.In(loc)
				}
				return shanghaiTime, nil
			}
			// RFC3339 格式已经包含时区信息，转换为Asia/Shanghai时区
			shanghaiTime := parsed.In(loc)
			return shanghaiTime, nil
		}
	}
	return time.Time{}, fmt.Errorf("无效的时间格式: %s", t)
}

// CreateBooking 创建预订
func (h *Handler) CreateBooking(c *gin.Context) {
	var req struct {
		UserID    uint   `json:"user_id" binding:"required"`
		VehicleID uint   `json:"vehicle_id" binding:"required"` // 添加车辆ID字段
		LotID     uint   `json:"lot_id" binding:"required"`
		Start     string `json:"start_time" binding:"required"`
		End       string `json:"end_time" binding:"required"`
		SpaceType string `json:"space_type"` // 可选，车位类型：普通、充电桩等
	}

	// 参数绑定验证
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, errorResponse(400, "参数错误: "+err.Error()))
		return
	}

	// 时间格式转换（增加错误处理）
	start, err := parseFlexibleTime(req.Start)
	if err != nil {
		c.JSON(http.StatusBadRequest, errorResponse(400, "开始时间格式错误"))
		return
	}

	end, err := parseFlexibleTime(req.End)
	if err != nil {
		c.JSON(http.StatusBadRequest, errorResponse(400, "结束时间格式错误"))
		return
	}

	// 如果未指定车位类型，默认为"普通"
	spaceType := req.SpaceType
	if spaceType == "" {
		spaceType = "普通"
	}

	// 调用业务层
	booking, err := h.service.CreateBooking(req.UserID, req.VehicleID, req.LotID, start, end, spaceType)
	if err != nil {
		c.JSON(http.StatusBadRequest, errorResponse(400, err.Error()))
		return
	}

	// 创建响应结构，格式化时间字段（去除时区后缀）
	response := map[string]interface{}{
		"order_id":          booking.OrderID,
		"user_id":           booking.UserID,
		"vehicle_id":        booking.VehicleID,
		"lot_id":            booking.LotID,
		"space_id":          booking.SpaceID,
		"start_time":        booking.StartTime.Format("2006-01-02 15:04:05"),      // 格式化为本地时间字符串（不带时区）
		"end_time":          booking.EndTime.Format("2006-01-02 15:04:05"),        // 格式化为本地时间字符串（不带时区）
		"booking_time":      booking.BookingTime.Format("2006-01-02 15:04:05"),    // 格式化为本地时间字符串（不带时区）
		"duration_minut":    booking.DurationMinutes,
		"status":            booking.Status,
		"total_fee":         booking.TotalFee,
		"paid_fee":          booking.PaidFee,
		"payment_status":   booking.PaymentStatus,
		"reservation_cod":   booking.ReservationCode,
		"space":             booking.Space,
		"lot":               booking.Lot,
		"vehicle":           booking.Vehicle,
	}
	if booking.ActualEndTime != nil {
		response["actual_end_time"] = booking.ActualEndTime.Format("2006-01-02 15:04:05")
	}

	c.JSON(http.StatusOK, successResponse(response))
}

// CancelBooking 取消预订（改进错误处理）
func (h *Handler) CancelBooking(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, errorResponse(400, "无效的预订ID"+err.Error()))
		return
	}

	if err := h.service.CancelBooking(uint(id)); err != nil {
		c.JSON(http.StatusBadRequest, errorResponse(400, err.Error()))
		return
	}

	c.JSON(http.StatusOK, successResponse(gin.H{"message": "预订取消成功"}))
}

// GetUserBookings 获取用户预订列表（改进错误处理）
func (h *Handler) GetUserBookings(c *gin.Context) {
	userIDStr := c.Query("user_id")
	if userIDStr == "" {
		c.JSON(http.StatusBadRequest, errorResponse(400, "缺少user_id参数"))
		return
	}

	userID, err := strconv.Atoi(userIDStr)
	if err != nil || userID <= 0 {
		c.JSON(http.StatusBadRequest, errorResponse(400, "无效的用户ID"))
		return
	}

	list, err := h.service.GetUserBookings(uint(userID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, errorResponse(500, "系统错误"+err.Error()))
		return
	}

	// 格式化时间字段，去除时区后缀
	formattedList := make([]map[string]interface{}, len(list))
	for i := range list {
		formattedList[i] = formatReservationOrder(&list[i])
	}

	c.JSON(http.StatusOK, successResponse(formattedList))
}

// GetBookingDetail 获取预订详情（新增接口）
func (h *Handler) GetBookingDetail(c *gin.Context) {
	idStr := c.Param("id")
	id, err := strconv.Atoi(idStr)
	if err != nil || id <= 0 {
		c.JSON(http.StatusBadRequest, errorResponse(400, "无效的预订ID"))
		return
	}

	booking, err := h.service.GetBookingDetail(uint(id))
	if err != nil {
		c.JSON(http.StatusNotFound, errorResponse(404, "预订不存在"))
		return
	}

	// 格式化时间字段，去除时区后缀
	formatted := formatReservationOrder(booking)
	c.JSON(http.StatusOK, successResponse(formatted))
}

// CheckAndUpdateExpiredBookings 检查并更新超时的预订记录
func (h *Handler) CheckAndUpdateExpiredBookings(c *gin.Context) {
	count, err := h.service.CheckAndUpdateExpiredBookings()
	if err != nil {
		c.JSON(http.StatusInternalServerError, errorResponse(500, "检查超时预订失败: "+err.Error()))
		return
	}

	c.JSON(http.StatusOK, successResponse(gin.H{
		"updated_count": count,
		"message":       fmt.Sprintf("已更新 %d 条超时预订记录", count),
	}))
}

// formatReservationOrder 格式化预订订单，去除时间字段的时区后缀
func formatReservationOrder(booking *model.ReservationOrder) map[string]interface{} {
	result := map[string]interface{}{
		"order_id":        booking.OrderID,
		"user_id":         booking.UserID,
		"vehicle_id":      booking.VehicleID,
		"lot_id":          booking.LotID,
		"space_id":        booking.SpaceID,
		"start_time":      booking.StartTime.Format("2006-01-02 15:04:05"),
		"end_time":        booking.EndTime.Format("2006-01-02 15:04:05"),
		"booking_time":    booking.BookingTime.Format("2006-01-02 15:04:05"),
		"duration_minut":  booking.DurationMinutes,
		"status":          booking.Status,
		"total_fee":       booking.TotalFee,
		"paid_fee":        booking.PaidFee,
		"payment_status":  booking.PaymentStatus,
		"reservation_cod": booking.ReservationCode,
	}
	if booking.ActualEndTime != nil {
		result["actual_end_time"] = booking.ActualEndTime.Format("2006-01-02 15:04:05")
	}
	if booking.Space.SpaceID > 0 {
		result["space"] = booking.Space
	}
	if booking.Lot.LotID > 0 {
		result["lot"] = booking.Lot
	}
	if booking.Vehicle.VehicleID > 0 {
		result["vehicle"] = booking.Vehicle
	}
	return result
}
