package controller

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

// ==================== 通用函数 ====================

// findActiveParkingRecordByLicensePlate 根据车牌号查找在场停车记录
func findActiveParkingRecordByLicensePlate(licensePlate string) (*model.ParkingRecord, *model.ParkingSpace, *model.ParkingLot, error) {
	var record model.ParkingRecord
	var vehicle model.Vehicle

	// 先查找车辆
	err := inits.DB.Where("license_plate = ?", licensePlate).First(&vehicle).Error
	if err != nil {
		return nil, nil, nil, err
	}

	// 查找在场停车记录
	err = inits.DB.
		Where("vehicle_id = ?", vehicle.VehicleID).
		Where("record_status = ?", 1). // 1-在场
		Preload("Space").
		Preload("Lot").
		Preload("Vehicle").
		First(&record).Error

	if err != nil {
		return nil, nil, nil, err
	}

	return &record, &record.Space, &record.Lot, nil
}

// findActiveParkingRecordsByUserID 根据用户ID查找在场停车记录
func findActiveParkingRecordsByUserID(userID uint) ([]model.ParkingRecord, error) {
	var records []model.ParkingRecord
	err := inits.DB.
		Where("user_id = ?", userID).
		Where("record_status = ?", 1). // 1-在场
		Preload("Vehicle").
		Preload("Space").
		Preload("Lot").
		Find(&records).Error

	return records, err
}

// updateSpaceStatus 更新车位状态
func updateSpaceStatus(tx *gorm.DB, spaceID uint, occupied bool) error {
	status := int8(0)
	if occupied {
		status = 1
	}

	return tx.Model(&model.ParkingSpace{}).
		Where("space_id = ?", spaceID).
		Updates(map[string]interface{}{
			"is_occupied": status,
			"last_update": time.Now(),
		}).Error
}

// updateReservationStatus 更新预约状态
func updateReservationStatus(tx *gorm.DB, reservationID uint, status int8) error {
	return tx.Model(&model.ReservationOrder{}).
		Where("order_id = ?", reservationID).
		Updates(map[string]interface{}{
			"status": status,
		}).Error
}

// calculateParkingFee 计算停车费用
func calculateParkingFee(duration time.Duration, hourlyRate float64) float64 {
	// 计算小时数（向上取整）
	hours := duration.Hours()
	if hours < 1 {
		hours = 1 // 不足1小时按1小时计费
	} else if hours > float64(int(hours)) {
		hours = float64(int(hours) + 1) // 超过整小时部分按1小时计费
	}

	return hours * hourlyRate
}

// checkViolations 检查违规记录
func checkViolations(recordID uint) (float64, bool) {
	var violations []model.ViolationRecord
	err := inits.DB.
		Where("record_id = ?", recordID).
		Where("status = ?", 0). // 0-未处理
		Find(&violations).Error

	if err != nil || len(violations) == 0 {
		return 0, false
	}

	// 计算总罚款金额
	totalFine := 0.0
	for _, v := range violations {
		totalFine += v.FineAmount
	}

	return totalFine, true
}

// ==================== 车辆入场功能 ====================

// VehicleEntryRequest 车辆入场请求
type VehicleEntryRequest struct {
	LicensePlate string `json:"license_plate" binding:"required"` // 车牌号
	SpaceType    string `json:"space_type"`                       // 车位类型（普通、充电桩等）
}

// VehicleEntryResponse 车辆入场响应
type VehicleEntryResponse struct {
	RecordID      uint      `json:"record_id"`      // 停车记录ID
	SpaceID       uint      `json:"space_id"`       // 分配的车位ID
	SpaceNumber   string    `json:"space_number"`   // 车位编号
	Level         int       `json:"level"`          // 所在楼层
	LotName       string    `json:"lot_name"`       // 停车场名称
	EntryTime     time.Time `json:"entry_time"`     // 入场时间
	ReservationID *uint     `json:"reservation_id"` // 关联的预约ID（如果有）
}

// VehicleEntry 处理车辆入场
func VehicleEntry(c *gin.Context) {
	var req VehicleEntryRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求参数"})
		return
	}

	// 开启事务
	tx := inits.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "服务器内部错误"})
		}
	}()

	// 1. 根据车牌号查找车辆信息
	vehicle, user, err := findVehicleAndUser(req.LicensePlate)
	if err != nil {
		tx.Rollback()
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "未找到车辆信息"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车辆信息失败"})
		}
		return
	}

	// 2. 检查是否有有效的预约
	reservation, space, lot, err := findValidReservation(vehicle.VehicleID)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询预约信息失败"})
		return
	}

	// 3. 如果没有有效预约，分配新车位
	if reservation == nil {
		space, lot, err = assignNewSpace(req.SpaceType)
		if err != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "分配车位失败: " + err.Error()})
			return
		}
	}

	// 4. 创建停车记录
	record, err := createParkingRecord(tx, user.UserID, vehicle.VehicleID, space.SpaceID, lot.LotID)
	if err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "创建停车记录失败"})
		return
	}

	// 5. 更新车位状态
	if err := updateSpaceStatus(tx, space.SpaceID, true); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新车位状态失败"})
		return
	}

	// 6. 如果有预约，更新预约状态
	if reservation != nil {
		if err := updateReservationStatus(tx, reservation.OrderID, 2); err != nil { // 2-使用中
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "更新预约状态失败"})
			return
		}
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "事务提交失败"})
		return
	}

	// 构建响应
	resp := VehicleEntryResponse{
		RecordID:      record.RecordID,
		SpaceID:       space.SpaceID,
		SpaceNumber:   space.SpaceNumber,
		Level:         space.Level,
		LotName:       lot.Name,
		EntryTime:     record.EntryTime,
		ReservationID: nil,
	}

	if reservation != nil {
		resp.ReservationID = &reservation.OrderID
	}

	c.JSON(http.StatusOK, resp)
}

// findVehicleAndUser 根据车牌号查找车辆和用户信息
func findVehicleAndUser(licensePlate string) (*model.Vehicle, *model.Users_list, error) {
	var vehicle model.Vehicle
	if err := inits.DB.Where("license_plate = ?", licensePlate).
		Preload("User").
		First(&vehicle).Error; err != nil {
		return nil, nil, err
	}
	return &vehicle, &vehicle.User, nil
}

// findValidReservation 查找有效的预约
func findValidReservation(vehicleID uint) (*model.ReservationOrder, *model.ParkingSpace, *model.ParkingLot, error) {
	now := time.Now()
	var reservation model.ReservationOrder

	// 查找当前时间在预约时间段内且状态为已预订的预约
	err := inits.DB.
		Where("vehicle_id = ?", vehicleID).
		Where("start_time <= ? AND end_time >= ?", now, now).
		Where("status = ?", 1). // 1-已预订
		Preload("Space").
		Preload("Lot").
		First(&reservation).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, nil, gorm.ErrRecordNotFound
		}
		return nil, nil, nil, err
	}

	// 检查预约的车位是否可用
	if reservation.Space.IsOccupied == 1 {
		return nil, nil, nil, errors.New("预约车位已被占用")
	}

	return &reservation, &reservation.Space, &reservation.Lot, nil
}

// assignNewSpace 分配新车位
func assignNewSpace(spaceType string) (*model.ParkingSpace, *model.ParkingLot, error) {
	// 查找指定类型的可用车位
	var space model.ParkingSpace
	err := inits.DB.
		Where("space_type = ?", spaceType).
		Where("is_occupied = ?", 0). // 未被占用
		Where("is_reserved = ?", 0). // 未被预订
		Where("status = ?", 1).      // 状态可用
		Preload("Lot").              // 关联停车场信息
		Order("space_id").           // 按顺序分配
		First(&space).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// 如果没有指定类型的车位，尝试分配普通车位
			if spaceType != "普通" {
				return assignNewSpace("普通")
			}
			return nil, nil, errors.New("没有可用车位")
		}
		return nil, nil, err
	}

	return &space, &space.Lot, nil
}

// createParkingRecord 创建停车记录
func createParkingRecord(tx *gorm.DB, userID, vehicleID, spaceID, lotID uint) (*model.ParkingRecord, error) {
	record := model.ParkingRecord{
		UserID:        userID,
		VehicleID:     vehicleID,
		SpaceID:       spaceID,
		LotID:         lotID,
		EntryTime:     time.Now(),
		RecordStatus:  1, // 1-在场
		IsViolation:   0, // 初始无违规
		PaymentStatus: 0, // 0-未支付
	}

	if err := tx.Create(&record).Error; err != nil {
		return nil, err
	}

	return &record, nil
}

// ==================== 辅助功能 ====================

// GetParkingSpaceTypes 获取可用的车位类型
func GetParkingSpaceTypes(c *gin.Context) {
	// 从数据库中查询所有不同的车位类型
	var spaceTypes []string
	if err := inits.DB.Model(&model.ParkingSpace{}).
		Distinct("space_type").
		Pluck("space_type", &spaceTypes).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "获取车位类型失败"})
		return
	}

	// 如果没有查询到类型，返回默认类型
	if len(spaceTypes) == 0 {
		spaceTypes = []string{"普通", "残疾人", "充电桩", "VIP"}
	}

	c.JSON(http.StatusOK, spaceTypes)
}

// GetUserActiveParkingRecords 获取用户当前在场停车记录
func GetUserActiveParkingRecords(c *gin.Context) {
	userIDStr := c.Param("user_id")
	if userIDStr == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "用户ID不能为空"})
		return
	}

	// 将字符串类型的用户ID转换为uint
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
		return
	}

	records, err := findActiveParkingRecordsByUserID(uint(userID))
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询停车记录失败"})
		return
	}

	if len(records) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到在场停车记录"})
		return
	}

	c.JSON(http.StatusOK, records)
}

// GetParkingLotSpaces 获取停车场车位信息
func GetParkingLotSpaces(c *gin.Context) {
	lotID := c.Param("lot_id")
	if lotID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "停车场ID不能为空"})
		return
	}

	var spaces []model.ParkingSpace
	err := inits.DB.
		Where("lot_id = ?", lotID).
		Preload("Lot").
		Find(&spaces).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车位信息失败"})
		return
	}

	if len(spaces) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到车位信息"})
		return
	}

	c.JSON(http.StatusOK, spaces)
}

// GetVehicleByLicensePlate 根据车牌号获取车辆信息
func GetVehicleByLicensePlate(c *gin.Context) {
	licensePlate := c.Param("license_plate")
	if licensePlate == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "车牌号不能为空"})
		return
	}

	var vehicle model.Vehicle
	err := inits.DB.
		Where("license_plate = ?", licensePlate).
		Preload("User").
		First(&vehicle).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "未找到车辆信息"})
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车辆信息失败"})
		}
		return
	}

	c.JSON(http.StatusOK, vehicle)
}

type OccupancyInfo struct {
	SpaceType string `json:"space_type"`
	Total     int64  `json:"total"`
	Occupied  int64  `json:"occupied"`
	Available int64  `json:"available"`
}

// GetParkingLotOccupancy 获取停车场车位占用情况
func GetParkingLotOccupancy(c *gin.Context) {
	lotID := c.Param("lot_id")
	if lotID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "停车场ID不能为空"})
		return
	}

	var results []OccupancyInfo
	err := inits.DB.
		Model(&model.ParkingSpace{}).
		Select("space_type, COUNT(*) as total, SUM(is_occupied) as occupied, COUNT(*) - SUM(is_occupied) as available").
		Where("lot_id = ?", lotID).
		Group("space_type").
		Scan(&results).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车位占用情况失败"})
		return
	}

	if len(results) == 0 {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到车位信息"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"lot_id":    lotID,
		"occupancy": results,
	})
}

// ==================== 车辆出场功能 ====================

// VehicleExitRequest 车辆出场请求
type VehicleExitRequest struct {
	LicensePlate string `json:"license_plate" binding:"required"` // 车牌号
}

// VehicleExitResponse 车辆出场响应
type VehicleExitResponse struct {
	RecordID      uint      `json:"record_id"`      // 停车记录ID
	SpaceID       uint      `json:"space_id"`       // 车位ID
	SpaceNumber   string    `json:"space_number"`   // 车位编号
	LotName       string    `json:"lot_name"`       // 停车场名称
	EntryTime     time.Time `json:"entry_time"`     // 入场时间
	ExitTime      time.Time `json:"exit_time"`      // 出场时间
	DurationHours float64   `json:"duration_hours"` // 停车时长（小时）
	TotalFee      float64   `json:"total_fee"`      // 总费用
	IsViolation   bool      `json:"is_violation"`   // 是否有违规
	ViolationFee  float64   `json:"violation_fee"`  // 违规罚款金额
	PaymentURL    string    `json:"payment_url"`    // 支付链接
}

// VehicleExit 处理车辆出场
func VehicleExit(c *gin.Context) {
	var req VehicleExitRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求参数"})
		return
	}

	// 1. 先根据车牌号查找在场停车记录（在事务外查询，避免事务隔离问题）
	record, space, lot, err := findActiveParkingRecordByLicensePlate(req.LicensePlate)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusNotFound, gin.H{"error": "未找到在场停车记录"})
		} else {
			log.Printf("查询停车记录失败: %v", err)
			c.JSON(http.StatusInternalServerError, gin.H{"error": fmt.Sprintf("查询停车记录失败: %v", err)})
		}
		return
	}

	// 开启事务
	tx := inits.DB.Begin()
	defer func() {
		if r := recover(); r != nil {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "服务器内部错误"})
		}
	}()

	// 在事务内重新加载记录，确保使用事务的DB实例
	var txRecord model.ParkingRecord
	if err := tx.First(&txRecord, record.RecordID).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "在事务内查询停车记录失败"})
		return
	}
	record = &txRecord

	// 重新加载关联数据
	var txSpace model.ParkingSpace
	var txLot model.ParkingLot
	if err := tx.First(&txSpace, record.SpaceID).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车位信息失败"})
		return
	}
	if err := tx.First(&txLot, record.LotID).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询停车场信息失败"})
		return
	}
	space = &txSpace
	lot = &txLot

	// 2. 更新停车记录
	exitTime := time.Now()
	duration := exitTime.Sub(record.EntryTime)
	durationMinutes := int(duration.Minutes())

	// 计算停车费用
	hourlyRate := lot.HourlyRate
	totalFee := calculateParkingFee(duration, hourlyRate)

	// 检查是否有违规记录
	violationFee, hasViolation := checkViolations(record.RecordID)

	// 更新停车记录
	record.ExitTime = &exitTime
	record.DurationMinutes = durationMinutes
	record.FeeCalculated = totalFee
	record.RecordStatus = 2 // 2-已出场
	record.IsViolation = 0
	if hasViolation {
		record.IsViolation = 1
	}

	if err := tx.Save(record).Error; err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新停车记录失败"})
		return
	}

	// 3. 释放车位
	if err := updateSpaceStatus(tx, space.SpaceID, false); err != nil {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "释放车位失败"})
		return
	}

	// 4. 查找关联的预约记录
	reservation, err := findActiveReservation(record.VehicleID, record.EntryTime)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询预约信息失败"})
		return
	}

	// 5. 如果有预约，更新预约状态
	if reservation != nil {
		if err := updateReservationStatus(tx, reservation.OrderID, 3); err != nil { // 3-已完成
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "更新预约状态失败"})
			return
		}
	}

	// 提交事务
	if err := tx.Commit().Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "事务提交失败"})
		return
	}

	// 6. 检查支付服务是否已初始化
	if PaymentService == nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "支付服务未初始化"})
		return
	}

	// 7. 生成统一支付链接
	amount := totalFee + violationFee
	redirectURL, paymentID, err := PaymentService.CreatePayment(
		record.RecordID,
		"parking", // 类型：停车付费
		"alipay",  // 可改成前端传的
		&amount,
	)
	if err != nil {
		log.Printf("生成支付链接失败: %v", err)
	}

	// 记录 paymentID 用于调试
	log.Printf("生成的支付ID: %d", paymentID)

	// 构建响应
	resp := VehicleExitResponse{
		RecordID:      record.RecordID,
		SpaceID:       space.SpaceID,
		SpaceNumber:   space.SpaceNumber,
		LotName:       lot.Name,
		EntryTime:     record.EntryTime,
		ExitTime:      exitTime,
		DurationHours: duration.Hours(),
		TotalFee:      amount,
		IsViolation:   hasViolation,
		ViolationFee:  violationFee,
		PaymentURL:    redirectURL, // 统一 paymentService 返回的 URL
	}

	c.JSON(http.StatusOK, resp)

}

// findActiveReservation 查找有效的预约
func findActiveReservation(vehicleID uint, entryTime time.Time) (*model.ReservationOrder, error) {
	var reservation model.ReservationOrder

	// 查找入场时间在预约时间段内且状态为使用中的预约
	err := inits.DB.
		Where("vehicle_id = ?", vehicleID).
		Where("start_time <= ? AND end_time >= ?", entryTime, entryTime).
		Where("status = ?", 2). // 2-使用中
		First(&reservation).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, err
	}

	return &reservation, nil
}
