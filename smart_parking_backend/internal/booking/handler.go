package booking

import (
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
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
func parseFlexibleTime(t string) (time.Time, error) {
	layouts := []string{
		time.RFC3339,
		"2006-01-02 15:04:05",
		"2006/01/02 15:04:05",
	}

	for _, layout := range layouts {
		if parsed, err := time.Parse(layout, t); err == nil {
			return parsed, nil
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

	c.JSON(http.StatusOK, successResponse(booking))
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

	c.JSON(http.StatusOK, successResponse(list))
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

	c.JSON(http.StatusOK, successResponse(booking))
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
