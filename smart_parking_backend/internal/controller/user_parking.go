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
	SpaceType    string `json:"space_type"`                        // 车位类型（普通、充电桩等）
	LotID        uint   `json:"lot_id"`                            // 停车场ID（可选，如果提供则用于精确匹配预订）
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

	// 2. 检查是否有有效的预约（使用事务查询）
	// 严格按照用户要求：按车牌号、停车场、当前时间筛选
	// 如果提供了停车场ID，则必须匹配该停车场；否则不限制停车场（兼容旧逻辑）
	var reservation *model.ReservationOrder
	var space *model.ParkingSpace
	var lot *model.ParkingLot
	if req.LotID > 0 {
		// 如果提供了停车场ID，必须按停车场匹配
		reservation, space, lot, err = findValidReservationWithTx(tx, vehicle.VehicleID, req.LotID)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询预约信息失败"})
			return
		}
	} else {
		// 如果没有提供停车场ID，则不限制停车场（兼容旧逻辑）
		reservation, space, lot, err = findValidReservationWithTx(tx, vehicle.VehicleID, 0)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			tx.Rollback()
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询预约信息失败"})
			return
		}
	}

	// 3. 如果没有有效预约，分配新车位（使用事务查询）
	if reservation == nil {
		space, lot, err = assignNewSpaceWithTx(tx, req.SpaceType)
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

// findValidReservation 查找有效的预约（使用非事务DB，用于兼容旧代码）
func findValidReservation(vehicleID uint) (*model.ReservationOrder, *model.ParkingSpace, *model.ParkingLot, error) {
	return findValidReservationWithTx(inits.DB, vehicleID, 0)
}

// findValidReservationByVehicleAndLot 根据车辆ID和停车场ID查找有效预订（用于检查预订接口）
func findValidReservationByVehicleAndLot(vehicleID uint, lotID uint) (*model.ReservationOrder, *model.ParkingSpace, *model.ParkingLot, error) {
	return findValidReservationWithTx(inits.DB, vehicleID, lotID)
}

// findValidReservationWithTx 查找有效的预约（支持事务）
// 严格按照用户要求：按车牌号（vehicleID）、停车场（lotID）、当前时间筛选
// 查找当前时间在预约时间段内且状态为已预订的预约
func findValidReservationWithTx(db *gorm.DB, vehicleID uint, lotID uint) (*model.ReservationOrder, *model.ParkingSpace, *model.ParkingLot, error) {
	now := time.Now()
	var reservation model.ReservationOrder

	// 查找当前时间在预约时间段内且状态为已预订的预约
	// 允许在预订开始时间前30分钟内入场（给予缓冲时间）
	bufferTime := 30 * time.Minute
	earliestEntryTime := now.Add(-bufferTime)
	
	// 构建查询条件：必须匹配车牌号、当前时间
	query := db.
		Where("vehicle_id = ?", vehicleID).
		Where("start_time <= ? AND end_time >= ?", now.Add(bufferTime), earliestEntryTime).
		Where("status = ?", 1) // 1-已预订
	
	// 如果提供了停车场ID，则必须匹配停车场（严格要求）
	if lotID > 0 {
		query = query.Where("lot_id = ?", lotID)
	}
	
	// 执行查询
	err := query.
		Preload("Space").
		Preload("Lot").
		Preload("Vehicle"). // 预加载车辆信息
		Order("start_time ASC"). // 如果有多个，选择最早开始的
		First(&reservation).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, nil, gorm.ErrRecordNotFound
		}
		return nil, nil, nil, err
	}

	// 检查预约的车位是否可用（如果已被占用，仍然可以使用预订车位）
	// 注意：这里不检查IsOccupied，因为预订车位应该优先使用

	return &reservation, &reservation.Space, &reservation.Lot, nil
}

// assignNewSpace 分配新车位（使用非事务DB，用于兼容旧代码）
func assignNewSpace(spaceType string) (*model.ParkingSpace, *model.ParkingLot, error) {
	return assignNewSpaceWithTx(inits.DB, spaceType)
}

// assignNewSpaceWithTx 分配新车位（支持事务）
func assignNewSpaceWithTx(db *gorm.DB, spaceType string) (*model.ParkingSpace, *model.ParkingLot, error) {
	// 查找指定类型的可用车位
	var space model.ParkingSpace
	err := db.
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
				return assignNewSpaceWithTx(db, "普通")
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

	// 如果没有记录，返回空数组而不是404，这是RESTful API的最佳实践
	// 404应该用于资源不存在（如用户不存在），而不是查询结果为空
	if len(records) == 0 {
		c.JSON(http.StatusOK, []model.ParkingRecord{})
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

// CheckValidReservationRequest 检查有效预订请求
type CheckValidReservationRequest struct {
	LicensePlate string `json:"license_plate" binding:"required"` // 车牌号
	LotID        uint   `json:"lot_id" binding:"required"`         // 停车场ID（必填，用于精确匹配）
}

// CheckValidReservationResponse 检查有效预订响应
type CheckValidReservationResponse struct {
	HasReservation bool                      `json:"has_reservation"` // 是否有有效预订
	Reservation    *model.ReservationOrder  `json:"reservation,omitempty"` // 预订信息（如果有）
	Space          *model.ParkingSpace       `json:"space,omitempty"`      // 车位信息（如果有）
	Lot            *model.ParkingLot         `json:"lot,omitempty"`        // 停车场信息（如果有）
}

// CheckValidReservation 检查车辆是否有有效预订（用于进场前确认）
func CheckValidReservation(c *gin.Context) {
	var req CheckValidReservationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的请求参数"})
		return
	}

	// 1. 根据车牌号查找车辆信息
	vehicle, _, err := findVehicleAndUser(req.LicensePlate)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusOK, CheckValidReservationResponse{
				HasReservation: false,
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车辆信息失败"})
		return
	}

	// 2. 查找有效预订（必须按车牌号、停车场、当前时间筛选）
	// 严格按照用户要求：车牌号、停车场、当前时间
	if req.LotID == 0 {
		c.JSON(http.StatusBadRequest, gin.H{"error": "停车场ID不能为空"})
		return
	}
	reservation, space, lot, err := findValidReservationByVehicleAndLot(vehicle.VehicleID, req.LotID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			c.JSON(http.StatusOK, CheckValidReservationResponse{
				HasReservation: false,
			})
			return
		}
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询预订信息失败"})
		return
	}

	// 3. 预加载车辆信息到预订对象中
	if err := inits.DB.Preload("Vehicle").First(reservation, reservation.OrderID).Error; err != nil {
		log.Printf("Warning: Failed to preload vehicle info for reservation: %v", err)
	}

	// 4. 返回预订信息
	c.JSON(http.StatusOK, CheckValidReservationResponse{
		HasReservation: true,
		Reservation:    reservation,
		Space:          space,
		Lot:            lot,
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

	// 4. 查找关联的预约记录（使用事务查询）
	// 严格按照用户要求：按车牌号、停车场、停车位类型、停车位序号，按离场时间最近的一次预订时间筛选
	reservation, err := findActiveReservationForExit(tx, record.VehicleID, record.LotID, space.SpaceType, space.SpaceNumber, exitTime)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		tx.Rollback()
		c.JSON(http.StatusInternalServerError, gin.H{"error": "查询预约信息失败"})
		return
	}

	// 5. 如果有预约且状态为"使用中"，更新预约状态为已完成
	// 严格按照用户要求：如果第一条预订订单状态为"使用中"，则改为"已完成"；如果第一条是其它状态，则不更改
	if reservation != nil && reservation.Status == 2 { // 2-使用中
		actualEndTime := exitTime
		if err := tx.Model(&model.ReservationOrder{}).
			Where("order_id = ?", reservation.OrderID).
			Updates(map[string]interface{}{
				"status":          3, // 3-已完成
				"actual_end_time": &actualEndTime,
			}).Error; err != nil {
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
		// 即使支付创建失败，也返回离场成功，但提示用户需要手动支付
		// 前端可以根据PaymentURL是否为空来判断是否需要手动创建支付
		redirectURL = ""
		paymentID = 0
	} else {
		// 记录 paymentID 用于调试
		log.Printf("生成的支付ID: %d", paymentID)
	}

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

// findActiveReservation 查找有效的预约（使用非事务DB，用于兼容旧代码）
func findActiveReservation(vehicleID uint, entryTime time.Time) (*model.ReservationOrder, error) {
	return findActiveReservationWithTx(inits.DB, vehicleID, entryTime)
}

// findActiveReservationForExit 查找离场时关联的预约（支持事务）
// 严格按照用户要求：按车牌号、停车场、停车位类型、停车位序号，按离场时间最近的一次预订时间筛选
func findActiveReservationForExit(db *gorm.DB, vehicleID uint, lotID uint, spaceType string, spaceNumber string, exitTime time.Time) (*model.ReservationOrder, error) {
	var reservation model.ReservationOrder

	// 检查是否需要 JOIN parking_space 表
	needsJoin := spaceType != "" || spaceNumber != ""

	// 构建查询条件：必须匹配车牌号、停车场
	// 按离场时间最近的一次预订时间筛选（按预订开始时间降序排列，取第一条）
	// 使用表前缀避免列名歧义（当有 JOIN 时）
	query := db.Model(&model.ReservationOrder{})

	// 如果需要进行 JOIN，先执行 JOIN
	if needsJoin {
		query = query.Joins("JOIN parking_space ON reservation_order.space_id = parking_space.space_id")
		// 使用表前缀避免列名歧义
		query = query.Where("reservation_order.vehicle_id = ?", vehicleID).
			Where("reservation_order.lot_id = ?", lotID).
			Where("reservation_order.status = ?", 2) // 2-使用中，只查找状态为"使用中"的预订
	} else {
		// 没有 JOIN 时，不需要表前缀
		query = query.Where("vehicle_id = ?", vehicleID).
			Where("lot_id = ?", lotID).
			Where("status = ?", 2) // 2-使用中，只查找状态为"使用中"的预订
	}

	// 如果提供了停车位类型，则同时匹配
	if spaceType != "" {
		query = query.Where("parking_space.space_type = ?", spaceType)
	}

	// 如果提供了停车位序号，则同时匹配
	if spaceNumber != "" {
		query = query.Where("parking_space.space_number = ?", spaceNumber)
	}

	// 预加载关联数据
	query = query.Preload("Space").
		Preload("Lot").
		Preload("Vehicle")

	// 按预订开始时间降序排列，选择离场时间最近的一次预订（即最晚开始的预订）
	err := query.
		Order("reservation_order.start_time DESC").
		First(&reservation).Error

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, gorm.ErrRecordNotFound
		}
		return nil, err
	}

	return &reservation, nil
}

// findActiveReservationWithTx 查找有效的预约（支持事务）
// 查找与停车记录关联的预约，优先查找状态为使用中的，如果没有则查找已预订的
// 改进：放宽时间匹配条件，允许在预订时间段前后一定范围内匹配，提高容错性
// 注意：此函数保留用于兼容旧代码，新的离场逻辑应使用 findActiveReservationForExit
func findActiveReservationWithTx(db *gorm.DB, vehicleID uint, entryTime time.Time) (*model.ReservationOrder, error) {
	var reservation model.ReservationOrder

	// 允许的时间偏差：前后1小时（容错处理，避免时间精度问题）
	timeWindow := 1 * time.Hour
	earliestTime := entryTime.Add(-timeWindow)
	latestTime := entryTime.Add(timeWindow)

	// 先尝试查找状态为使用中的预约
	err := db.
		Where("vehicle_id = ?", vehicleID).
		Where("start_time <= ? AND end_time >= ?", latestTime, earliestTime).
		Where("status = ?", 2).   // 2-使用中
		Order("start_time DESC"). // 如果有多个，选择最晚开始的
		First(&reservation).Error

	if err == nil {
		return &reservation, nil
	}

	// 如果没找到使用中的，尝试查找已预订的预约（可能入场时状态更新失败）
	if errors.Is(err, gorm.ErrRecordNotFound) {
		err = db.
			Where("vehicle_id = ?", vehicleID).
			Where("start_time <= ? AND end_time >= ?", latestTime, earliestTime).
			Where("status = ?", 1). // 1-已预订
			Order("start_time DESC").
			First(&reservation).Error

		if err == nil {
			return &reservation, nil
		}
	}

	// 如果还是没找到，尝试更宽泛的匹配：扩大时间窗口到前后2小时
	if errors.Is(err, gorm.ErrRecordNotFound) {
		wideTimeWindow := 2 * time.Hour
		wideEarliestTime := entryTime.Add(-wideTimeWindow)
		wideLatestTime := entryTime.Add(wideTimeWindow)
		
		// 先查找使用中的
		err = db.
			Where("vehicle_id = ?", vehicleID).
			Where("(start_time <= ? AND end_time >= ?) OR (start_time <= ? AND start_time >= ?)", 
				wideLatestTime, wideEarliestTime, entryTime, wideEarliestTime).
			Where("status = ?", 2). // 2-使用中
			Order("start_time DESC").
			First(&reservation).Error

		if err == nil {
			return &reservation, nil
		}

		// 再查找已预订的
		if errors.Is(err, gorm.ErrRecordNotFound) {
			err = db.
				Where("vehicle_id = ?", vehicleID).
				Where("(start_time <= ? AND end_time >= ?) OR (start_time <= ? AND start_time >= ?)", 
					wideLatestTime, wideEarliestTime, entryTime, wideEarliestTime).
				Where("status = ?", 1). // 1-已预订
				Order("start_time DESC").
				First(&reservation).Error

			if err == nil {
				return &reservation, nil
			}
		}
	}

	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, gorm.ErrRecordNotFound
	}

	return nil, err
}
