package controller

import (
	"fmt"
	"log"
	"net/http"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"smart_parking_backend/internal/payment"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// ==================== 违规记录管理 ====================

// ViolationCheckRequest 违规检查请求
type ViolationCheckRequest struct {
	CheckType int `json:"check_type" binding:"required"` // 检查类型 (1-预订未使用, 2-超时停车, 3-未支付停车费, 4-未支付罚款)
}

// ViolationCheckResponse 违规检查响应
type ViolationCheckResponse struct {
	ViolationCount int `json:"violation_count"` // 发现的违规数量
}

// PaymentService 支付服务实例
var PaymentService *payment.Service

// InitPaymentService 初始化支付服务
func InitPaymentService(paymentSvc *payment.Service) {
	PaymentService = paymentSvc
}

// CheckViolations 检查违规行为
func CheckViolations(c *gin.Context) {
	var req ViolationCheckRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求参数"})
		return
	}

	var count int
	var err error

	switch req.CheckType {
	case 1:
		count, err = checkUnusedReservations()
	case 2:
		count, err = checkOvertimeParking()
	case 3:
		count, err = checkUnpaidParkingFees()
	case 4:
		count, err = checkUnpaidFines()
	default:
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的检查类型"})
		return
	}

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "检查违规失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, ViolationCheckResponse{ViolationCount: count})
}

// checkUnusedReservations 检查未使用的预订
func checkUnusedReservations() (int, error) {
	now := time.Now()
	halfHourAgo := now.Add(-30 * time.Minute)

	var reservations []model.ReservationOrder
	err := inits.DB.
		Where("status = ?", 1). // 1-已预订
		Where("start_time <= ?", halfHourAgo).
		Where("actual_end_time IS NULL"). // 未实际结束
		Preload("Space").
		Preload("Lot").
		Find(&reservations).Error

	if err != nil {
		return 0, err
	}

	count := 0
	for _, reservation := range reservations {
		// 创建违规记录
		// RecordID设为0（不关联停车记录），将相关信息记录到description中
		description := fmt.Sprintf("预订车位后未在预订开始时间后30分钟内使用。预订订单ID: %d", reservation.OrderID)
		violation := model.ViolationRecord{
			RecordID:      0, // 不关联停车记录
			UserID:        reservation.UserID,
			VehicleID:     reservation.VehicleID,
			ViolationType: "预订未使用",
			ViolationTime: now,
			Description:   description,
			FineAmount:    reservation.Lot.HourlyRate, // 罚款为1小时停车费
			Status:        0,                          // 0-未处理
		}

		if err := inits.DB.Create(&violation).Error; err != nil {
			log.Printf("创建违规记录失败: %v", err)
			continue
		}

		// 取消预约
		actualEndTime := now
		if err := inits.DB.Model(&reservation).
			Updates(map[string]interface{}{
				"status":          0, // 0-已取消
				"actual_end_time": &actualEndTime,
			}).Error; err != nil {
			log.Printf("取消预约失败: %v", err)
		}

		// 释放车位
		if err := inits.DB.Model(&model.ParkingSpace{}).
			Where("space_id = ?", reservation.SpaceID).
			Updates(map[string]interface{}{
				"is_reserved": 0,
				"last_update": now,
			}).Error; err != nil {
			log.Printf("释放车位失败: %v", err)
		}

		// 发送罚单 (简化实现)
		sendViolationNotice(reservation.UserID, violation.ViolationID)

		count++
	}

	return count, nil
}

// checkOvertimeParking 检查超时停车
func checkOvertimeParking() (int, error) {
	now := time.Now()
	halfHourAgo := now.Add(-30 * time.Minute)

	var reservations []model.ReservationOrder
	err := inits.DB.
		Where("status = ?", 2). // 2-使用中
		Where("end_time <= ?", halfHourAgo).
		Where("actual_end_time IS NULL"). // 未实际结束
		Preload("Space").
		Preload("Lot").
		Find(&reservations).Error

	if err != nil {
		return 0, err
	}

	count := 0
	for _, reservation := range reservations {
		// 创建违规记录
		// RecordID设为0（不关联停车记录），将相关信息记录到description中
		description := fmt.Sprintf("使用车位超出预订结束时间30分钟。预订订单ID: %d", reservation.OrderID)
		violation := model.ViolationRecord{
			RecordID:      0, // 不关联停车记录
			UserID:        reservation.UserID,
			VehicleID:     reservation.VehicleID,
			ViolationType: "超时停车",
			ViolationTime: now,
			Description:   description,
			FineAmount:    reservation.Lot.HourlyRate, // 罚款为1小时停车费
			Status:        0,                          // 0-未处理
		}

		if err := inits.DB.Create(&violation).Error; err != nil {
			log.Printf("创建违规记录失败: %v", err)
			continue
		}

		// 取消预约
		actualEndTime := now
		if err := inits.DB.Model(&reservation).
			Updates(map[string]interface{}{
				"status":          0, // 0-已取消
				"actual_end_time": &actualEndTime,
			}).Error; err != nil {
			log.Printf("取消预约失败: %v", err)
		}

		// 释放车位
		if err := inits.DB.Model(&model.ParkingSpace{}).
			Where("space_id = ?", reservation.SpaceID).
			Updates(map[string]interface{}{
				"is_reserved": 0,
				"last_update": now,
			}).Error; err != nil {
			log.Printf("释放车位失败: %v", err)
		}

		// 发送罚单 (简化实现)
		sendViolationNotice(reservation.UserID, violation.ViolationID)

		count++
	}

	return count, nil
}

// checkUnpaidParkingFees 检查未支付的停车费
func checkUnpaidParkingFees() (int, error) {
	now := time.Now()
	oneMonthAgo := now.AddDate(0, -1, 0)

	var records []model.ParkingRecord
	err := inits.DB.
		Where("payment_status = ?", 0). // 0-未支付
		Where("entry_time <= ?", oneMonthAgo).
		Preload("Lot").
		Find(&records).Error

	if err != nil {
		return 0, err
	}

	count := 0
	for _, record := range records {
		// 计算罚款金额 (剩余费用的两倍)
		remainingFee := record.FeeCalculated - record.FeePaid
		fineAmount := remainingFee * 2

		// 创建违规记录
		// RecordID设为0（不关联停车记录），将停车记录ID记录到description中
		description := fmt.Sprintf("停车费产生一个月后仍未支付。停车记录ID: %d", record.RecordID)
		violation := model.ViolationRecord{
			RecordID:      0, // 不关联停车记录
			UserID:        record.UserID,
			VehicleID:     record.VehicleID,
			ViolationType: "未支付停车费",
			ViolationTime: now,
			Description:   description,
			FineAmount:    fineAmount,
			Status:        0, // 0-未处理
		}

		if err := inits.DB.Create(&violation).Error; err != nil {
			log.Printf("创建违规记录失败: %v", err)
			continue
		}

		// 发送罚单 (简化实现)
		sendViolationNotice(record.UserID, violation.ViolationID)

		count++
	}

	return count, nil
}

// checkUnpaidFines 检查未支付的罚款
func checkUnpaidFines() (int, error) {
	now := time.Now()
	twoWeeksAgo := now.AddDate(0, 0, -14)

	var violations []model.ViolationRecord
	err := inits.DB.
		Where("status = ?", 0). // 0-未处理
		Where("violation_time <= ?", twoWeeksAgo).
		Find(&violations).Error

	if err != nil {
		return 0, err
	}

	count := 0
	for _, violation := range violations {
		// 创建新的违规记录
		// RecordID设为0（不关联停车记录），将原违规记录ID记录到description中
		description := fmt.Sprintf("罚款产生两周后仍未支付。原违规记录ID: %d", violation.ViolationID)
		if violation.RecordID > 0 {
			description += fmt.Sprintf("，关联停车记录ID: %d", violation.RecordID)
		}
		newViolation := model.ViolationRecord{
			RecordID:      0, // 不关联停车记录
			UserID:        violation.UserID,
			VehicleID:     violation.VehicleID,
			ViolationType: "未支付罚款",
			ViolationTime: now,
			Description:   description,
			FineAmount:    violation.FineAmount * 2, // 剩余罚款的两倍
			Status:        0,                        // 0-未处理
		}

		if err := inits.DB.Create(&newViolation).Error; err != nil {
			log.Printf("创建违规记录失败: %v", err)
			continue
		}

		// 发送罚单 (简化实现)
		sendViolationNotice(violation.UserID, newViolation.ViolationID)

		count++
	}

	return count, nil
}

// sendViolationNotice 发送违规通知 (简化实现)
func sendViolationNotice(userID uint, violationID uint) {
	// 在实际应用中，这里会调用通知服务发送短信、邮件或APP推送
	// 这里简化为记录日志
	log.Printf("发送罚单给用户 %d, 违规记录ID: %d", userID, violationID)
}

// GetUserViolations 获取用户违规记录
func GetUserViolations(c *gin.Context) {
	userID := c.Param("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户ID不能为空"})
		return
	}

	var violations []model.ViolationRecord
	err := inits.DB.
		Where("user_id = ?", userID).
		Preload("Record").
		Preload("Vehicle").
		Preload("User").
		Order("violation_time DESC").
		Find(&violations).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询违规记录失败"})
		return
	}

	if len(violations) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到违规记录"})
		return
	}

	c.JSON(http.StatusOK, violations)
}

// 用户获取自己的违规记录历史
func GetUserViolationHistory(c *gin.Context) {
	userID := c.Param("user_id")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户ID不能为空"})
		return
	}
	// 默认显示所有违规记录，不再支持status参数过滤

	var violations []model.ViolationRecord
	err := inits.DB.
		Where("user_id = ?", userID).
		Preload("Record").
		Preload("Vehicle").
		Preload("User").
		Order("violation_time DESC").
		Find(&violations).Error
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询违规记录失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"total": len(violations),
		"data":  violations,
	})
}

// PayViolationFine 支付罚款
func PayViolationFine(c *gin.Context) {
	vioIDStr := c.Param("violation_id")
	if vioIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "违规记录ID不能为空"})
		return
	}

	vioID, err := strconv.Atoi(vioIDStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的违规记录ID"})
		return
	}

	// 检查支付服务是否已初始化
	if PaymentService == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "支付服务未初始化"})
		return
	}

	// 1. 先查询违规记录是否存在，以及金额是否正确
	var violation model.ViolationRecord
	if err := inits.DB.First(&violation, vioID).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "违规记录不存在"})
		return
	}

	// 2. 检查是否已经处理/支付
	if violation.Status == 1 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "该违规记录已处理，无需重复支付"})
		return
	}

	// 3. 准备支付金额 (确保金额有效)
	amount := violation.FineAmount
	if amount <= 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "罚款金额无效"})
		return
	}

	// 4. 调用统一 payment service
	// 注意：这里显式传递了 amount，防止底层服务因为 nil 而报错或取不到值
	// 另外，paymentMethod 从前端传参获取可能更好，这里暂时保留 alipay 默认值
	paymentMethod := c.DefaultQuery("method", "alipay")

	redirectURL, paymentID, err := PaymentService.CreatePayment(
		uint(vioID),
		"violation", // 确保类型字符串正确
		paymentMethod,
		&amount, // 传递明确的金额指针
	)

	if err != nil {
		log.Printf("创建罚款支付失败: %v", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建支付失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":         0, // 明确返回 code 0 以匹配前端 QML 的成功判断
		"violation_id": vioID,
		"payment_id":   paymentID,
		"payment_url":  redirectURL,
		"redirect_url": redirectURL, // 增加冗余字段以兼容不同前端取值逻辑
	})
}
