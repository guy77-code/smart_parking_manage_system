// internal/controller/user_controller.go
package controller

import (
	"net/http"
	"regexp"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model" // 引入用户模型定义
	"smart_parking_backend/utils"
	"time"

	"github.com/gin-gonic/gin" // Gin Web框架
	"github.com/golang-jwt/jwt/v5"
	"github.com/redis/go-redis/v9" // Redis客户端
	"golang.org/x/crypto/bcrypt"   // 密码加密库
	"gorm.io/gorm"                 // ORM数据库操作库
)

// RegisterRequest 修改后的注册请求体，支持多辆车辆
type RegisterRequest struct {
	Users_list struct {
		Username string `json:"username" binding:"required,min=3,max=50"`
		Password string `json:"password" binding:"required,min=6,max=100"`
		Phone    string `json:"phone" binding:"required"`
		Email    string `json:"email"`
		RealName string `json:"real_name"`
	} `json:"users_list" binding:"required"`

	// 将单个Vehicle改为Vehicles切片，支持多辆车辆
	Vehicles []struct {
		LicensePlate string `json:"license_plate" binding:"required"`
		Brand        string `json:"brand"`
		Model        string `json:"model"`
		Color        string `json:"color"`
	} `json:"vehicles" binding:"required,min=1"` // 要求至少提供一辆车
}

// Register 用户注册处理函数（支持多辆车辆登记）
func Register(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req RegisterRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// 密码加密
		hash, err := bcrypt.GenerateFromPassword([]byte(req.Users_list.Password), bcrypt.DefaultCost)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
			return
		}

		// 构造用户对象
		user := model.Users_list{
			Username:     req.Users_list.Username,
			PasswordHash: string(hash),
			Phone:        req.Users_list.Phone,
			Email:        req.Users_list.Email,
			RealName:     req.Users_list.RealName,
			RegisterTime: time.Now(),
			Status:       1,
		}

		// 开启事务
		if err := db.Transaction(func(tx *gorm.DB) error {
			// 创建用户
			if err := tx.Create(&user).Error; err != nil {
				return err
			}

			// 遍历所有车辆，为每辆车创建记录
			for _, vehicleReq := range req.Vehicles {
				vehicle := model.Vehicle{
					UserID:       user.UserID, // 使用创建用户后生成的UserID
					LicensePlate: vehicleReq.LicensePlate,
					Brand:        vehicleReq.Brand,
					Model:        vehicleReq.Model,
					Color:        vehicleReq.Color,
					AddTime:      time.Now(),
				}

				// 插入车辆记录
				if err := tx.Create(&vehicle).Error; err != nil {
					return err
				}
			}
			return nil
		}); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "数据库事务失败: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message":             "用户注册成功",
			"user_id":             user.UserID,
			"vehicles_registered": len(req.Vehicles), // 返回注册的车辆数量
		})
	}
}

// SendLoginCode 发送登录验证码（模拟发送，实际项目中应集成短信服务）
func SendLoginCode(rdb *redis.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Phone string `json:"phone" binding:"required"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// 验证手机号格式
		if !utils.ValidatePhoneFormat(req.Phone) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "手机号格式不正确"})
			return
		}

		// 检查发送频率限制（防止恶意发送）
		rateLimitKey := "rate_limit:" + req.Phone
		if remaining, err := rdb.TTL(c.Request.Context(), rateLimitKey).Result(); err == nil && remaining > 0 {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":        "请求过于频繁，请稍后再试",
				"wait_seconds": int(remaining.Seconds()),
			})
			return
		}

		// 生成6位随机验证码
		code := utils.Generate6DigitCode()
		key := "login_code:" + req.Phone

		// 将验证码存入Redis，设置5分钟有效期
		if err := rdb.Set(c.Request.Context(), key, code, 5*time.Minute).Err(); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "系统错误，请重试"})
			return
		}

		// 设置频率限制（60秒内只能发送一次）
		rdb.Set(c.Request.Context(), rateLimitKey, "1", 60*time.Second)

		// 在实际项目中应调用短信服务（如阿里云/腾讯云）发送验证码
		// utils.SendSMS(req.Phone, code)

		c.JSON(http.StatusOK, gin.H{
			"message":      "验证码已发送至您的手机", // 明确的成功提示 [6](@ref)
			"expires_in":   300,           // 告知验证码有效期（秒）
			"code":         code,
			"resend_after": 60, // 可重发时间提示
		})
	}
}

// Login 支持两种模式：
// 1. 手机号 + 密码 登录
// 2. 手机号 + 验证码 登录（忘记密码场景）
func Login(db *gorm.DB, rdb *redis.Client) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req struct {
			Phone    string `json:"phone" binding:"required"` // 手机号必须
			Password string `json:"password"`                 // 可选
			Code     string `json:"code"`                     // 可选（验证码）
		}

		// 解析登录请求
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}

		if !utils.ValidatePhoneFormat(req.Phone) {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid phone number format"})
			return
		}
		// 查询用户是否存在
		var user model.Users_list
		if err := db.Where("phone = ?", req.Phone).First(&user).Error; err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "User not found"})
			return
		}

		// 用户被禁用
		if user.Status == 0 {
			c.JSON(http.StatusForbidden, gin.H{"error": "Account disabled"})
			return
		}

		// ✅ 模式一：密码登录
		if req.Password != "" {
			if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)) != nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid password"})
				return
			}
		} else if req.Code != "" {
			// ✅ 模式二：验证码登录
			codeKey := "login_code:" + req.Phone
			storedCode, err := rdb.Get(c.Request.Context(), codeKey).Result()
			if err == redis.Nil {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Verification code expired"})
				return
			} else if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "Redis error"})
				return
			}
			if storedCode != req.Code {
				c.JSON(http.StatusUnauthorized, gin.H{"error": "Invalid verification code"})
				return
			}
			// 登录成功后删除验证码，防止重复使用
			rdb.Del(c.Request.Context(), codeKey)
		} else {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Password or code required"})
			return
		}

		// ✅ 登录成功，更新最后登录时间
		now := time.Now()
		db.Model(&user).Update("last_login", &now)

		// ✅ 预加载车辆信息
		var vehicles []model.Vehicle
		db.Where("user_id = ?", user.UserID).Find(&vehicles)

		// ✅ 生成 JWT token
		token, _ := utils.GenerateToken(user.UserID, user.Username)

		// 构建车辆列表（转换为前端需要的格式）
		var vehicleList []gin.H
		for _, v := range vehicles {
			vehicleList = append(vehicleList, gin.H{
				"vehicle_id":    v.VehicleID,
				"license_plate": v.LicensePlate,
				"brand":         v.Brand,
				"model":         v.Model,
				"color":         v.Color,
			})
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "Login success",
			"user": gin.H{
				"id":       user.UserID,
				"username": user.Username,
				"phone":    user.Phone,
				"email":    user.Email,
				"vehicles": vehicleList,
			},
			"token": token,
		})
	}
}

// PaymentRecordWithDetails 带详细信息的支付记录响应结构
type PaymentRecordWithDetails struct {
	model.PaymentRecord
	OrderType    string                 `json:"order_type"`    // "reservation", "parking", "violation"
	OrderDetails map[string]interface{} `json:"order_details"` // 订单详细信息
}

func GetUserPaymentRecords(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从 Token 中解析 user_id
		userID, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权，请先登录"})
			return
		}

		// 解析分页参数
		page := utils.ParseInt(c.DefaultQuery("page", "1"), 1)
		pageSize := utils.ParseInt(c.DefaultQuery("page_size", "10"), 10)
		offset := (page - 1) * pageSize

		var total int64
		var payments []model.PaymentRecord

		// 查询总数
		db.Model(&model.PaymentRecord{}).Where("user_id = ?", userID).Count(&total)

		// 查询支付记录，关联订单
		err := db.Preload("Order").
			Where("user_id = ?", userID).
			Order("create_time DESC").
			Offset(offset).
			Limit(pageSize).
			Find(&payments).Error

		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询失败"})
			return
		}

		// 构建带详细信息的支付记录列表
		var recordsWithDetails []PaymentRecordWithDetails
		for _, payment := range payments {
			record := PaymentRecordWithDetails{
				PaymentRecord: payment,
				OrderType:     "reservation", // 默认类型
				OrderDetails:  make(map[string]interface{}),
			}

			// 根据TransactionNo判断订单类型
			transactionNo := payment.TransactionNo
			if len(transactionNo) >= 12 && transactionNo[:12] == "PENDING_VIO_" {
				// 违规订单
				record.OrderType = "violation"
				var violation model.ViolationRecord
				if err := db.Preload("Vehicle").Preload("Record").First(&violation, payment.OrderID).Error; err == nil {
					record.OrderDetails["violation_id"] = violation.ViolationID
					record.OrderDetails["violation_type"] = violation.ViolationType
					record.OrderDetails["violation_time"] = violation.ViolationTime
					record.OrderDetails["description"] = violation.Description
					record.OrderDetails["fine_amount"] = violation.FineAmount
					record.OrderDetails["status"] = violation.Status
					if violation.Vehicle.VehicleID > 0 {
						record.OrderDetails["vehicle"] = map[string]interface{}{
							"vehicle_id":    violation.Vehicle.VehicleID,
							"license_plate": violation.Vehicle.LicensePlate,
							"brand":         violation.Vehicle.Brand,
							"model":         violation.Vehicle.Model,
							"color":         violation.Vehicle.Color,
						}
					}
				}
			} else if len(transactionNo) >= 8 && transactionNo[:8] == "PENDING_" {
				// 可能是停车订单或预订订单，优先检查预订订单
				if payment.Order.OrderID > 0 {
					// 优先识别为预订订单（即使已进场，预订订单仍然是预订订单）
					record.OrderType = "reservation"
					record.OrderDetails["order_id"] = payment.Order.OrderID
					record.OrderDetails["reservation_cod"] = payment.Order.ReservationCode
					record.OrderDetails["start_time"] = payment.Order.StartTime
					record.OrderDetails["end_time"] = payment.Order.EndTime
					record.OrderDetails["status"] = payment.Order.Status
					// 如果预订订单已进场，也包含停车记录信息
					var parkingRecord model.ParkingRecord
					if err := db.Preload("Vehicle").Preload("Lot").Preload("Space").
						Where("vehicle_id = ?", payment.Order.VehicleID).
						Where("record_status = ?", 1). // 在场记录
						First(&parkingRecord).Error; err == nil {
						record.OrderDetails["parking_record_id"] = parkingRecord.RecordID
						record.OrderDetails["entry_time"] = parkingRecord.EntryTime
						if parkingRecord.ExitTime != nil {
							record.OrderDetails["exit_time"] = parkingRecord.ExitTime
						}
						record.OrderDetails["duration_minute"] = parkingRecord.DurationMinutes
					}
				} else {
					// 没有预订订单，尝试查找停车记录
					var parkingRecord model.ParkingRecord
					if err := db.Preload("Vehicle").Preload("Lot").Preload("Space").First(&parkingRecord, payment.OrderID).Error; err == nil {
						// 找到停车记录
						record.OrderType = "parking"
						record.OrderDetails["record_id"] = parkingRecord.RecordID
						record.OrderDetails["entry_time"] = parkingRecord.EntryTime
						if parkingRecord.ExitTime != nil {
							record.OrderDetails["exit_time"] = parkingRecord.ExitTime
						}
						record.OrderDetails["duration_minute"] = parkingRecord.DurationMinutes
						record.OrderDetails["fee_calculated"] = parkingRecord.FeeCalculated
						if parkingRecord.Lot.LotID > 0 {
							record.OrderDetails["lot"] = map[string]interface{}{
								"lot_id":  parkingRecord.Lot.LotID,
								"name":    parkingRecord.Lot.Name,
								"address": parkingRecord.Lot.Address,
							}
						}
						if parkingRecord.Vehicle.VehicleID > 0 {
							record.OrderDetails["vehicle"] = map[string]interface{}{
								"vehicle_id":    parkingRecord.Vehicle.VehicleID,
								"license_plate": parkingRecord.Vehicle.LicensePlate,
								"brand":         parkingRecord.Vehicle.Brand,
								"model":         parkingRecord.Vehicle.Model,
								"color":         parkingRecord.Vehicle.Color,
							}
						}
					}
				}
			} else {
				// 没有PENDING前缀，可能是已支付的订单，通过OrderID查找
				// 优先检查预订订单
				if payment.Order.OrderID > 0 {
					record.OrderType = "reservation"
					record.OrderDetails["order_id"] = payment.Order.OrderID
					record.OrderDetails["reservation_cod"] = payment.Order.ReservationCode
					record.OrderDetails["start_time"] = payment.Order.StartTime
					record.OrderDetails["end_time"] = payment.Order.EndTime
					record.OrderDetails["status"] = payment.Order.Status
					// 如果预订订单已完成，可能有关联的停车记录
					if payment.Order.Status == 3 && payment.Order.ActualEndTime != nil {
						var parkingRecord model.ParkingRecord
						if err := db.Preload("Vehicle").Preload("Lot").Preload("Space").
							Where("vehicle_id = ?", payment.Order.VehicleID).
							Where("exit_time IS NOT NULL").
							Order("exit_time DESC").
							First(&parkingRecord).Error; err == nil {
							record.OrderDetails["parking_record_id"] = parkingRecord.RecordID
							record.OrderDetails["entry_time"] = parkingRecord.EntryTime
							if parkingRecord.ExitTime != nil {
								record.OrderDetails["exit_time"] = parkingRecord.ExitTime
							}
							record.OrderDetails["duration_minute"] = parkingRecord.DurationMinutes
						}
					}
				} else {
					// 尝试查找停车记录
					var parkingRecord model.ParkingRecord
					if err := db.Preload("Vehicle").Preload("Lot").Preload("Space").First(&parkingRecord, payment.OrderID).Error; err == nil {
						record.OrderType = "parking"
						record.OrderDetails["record_id"] = parkingRecord.RecordID
						record.OrderDetails["entry_time"] = parkingRecord.EntryTime
						if parkingRecord.ExitTime != nil {
							record.OrderDetails["exit_time"] = parkingRecord.ExitTime
						}
						record.OrderDetails["duration_minute"] = parkingRecord.DurationMinutes
						record.OrderDetails["fee_calculated"] = parkingRecord.FeeCalculated
						if parkingRecord.Lot.LotID > 0 {
							record.OrderDetails["lot"] = map[string]interface{}{
								"lot_id":  parkingRecord.Lot.LotID,
								"name":    parkingRecord.Lot.Name,
								"address": parkingRecord.Lot.Address,
							}
						}
						if parkingRecord.Vehicle.VehicleID > 0 {
							record.OrderDetails["vehicle"] = map[string]interface{}{
								"vehicle_id":    parkingRecord.Vehicle.VehicleID,
								"license_plate": parkingRecord.Vehicle.LicensePlate,
								"brand":         parkingRecord.Vehicle.Brand,
								"model":         parkingRecord.Vehicle.Model,
								"color":         parkingRecord.Vehicle.Color,
							}
						}
					} else {
						// 尝试查找违规记录
						var violation model.ViolationRecord
						if err := db.Preload("Vehicle").Preload("Record").First(&violation, payment.OrderID).Error; err == nil {
							record.OrderType = "violation"
							record.OrderDetails["violation_id"] = violation.ViolationID
							record.OrderDetails["violation_type"] = violation.ViolationType
							record.OrderDetails["violation_time"] = violation.ViolationTime
							record.OrderDetails["description"] = violation.Description
							record.OrderDetails["fine_amount"] = violation.FineAmount
							record.OrderDetails["status"] = violation.Status
							if violation.Vehicle.VehicleID > 0 {
								record.OrderDetails["vehicle"] = map[string]interface{}{
									"vehicle_id":    violation.Vehicle.VehicleID,
									"license_plate": violation.Vehicle.LicensePlate,
									"brand":         violation.Vehicle.Brand,
									"model":         violation.Vehicle.Model,
									"color":         violation.Vehicle.Color,
								}
							}
						}
					}
				}
			}

			recordsWithDetails = append(recordsWithDetails, record)
		}

		c.JSON(http.StatusOK, gin.H{
			"total":     total,
			"page":      page,
			"page_size": pageSize,
			"records":   recordsWithDetails,
		})
	}
}

// GetUserVehicles 获取当前登录用户的车辆列表
// 路由：GET /api/v1/vehicles （需 UserAuthMiddleware 注入 user_id）
func GetUserVehicles(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从 Token 中解析 user_id
		userIDVal, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权，请先登录"})
			return
		}

		var userID uint
		switch v := userIDVal.(type) {
		case uint:
			userID = v
		case int:
			if v > 0 {
				userID = uint(v)
			}
		case int64:
			if v > 0 {
				userID = uint(v)
			}
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
			return
		}

		var vehicles []model.Vehicle
		if err := db.Where("user_id = ?", userID).Find(&vehicles).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车辆信息失败"})
			return
		}

		// 构造与登录接口类似的车辆返回结构（使用 snake_case 字段名）
		var vehicleList []gin.H
		for _, v := range vehicles {
			vehicleList = append(vehicleList, gin.H{
				"vehicle_id":    v.VehicleID,
				"license_plate": v.LicensePlate,
				"brand":         v.Brand,
				"model":         v.Model,
				"color":         v.Color,
			})
		}

		c.JSON(http.StatusOK, gin.H{
			"total": len(vehicleList),
			"data":  vehicleList,
		})
	}
}

// AddUserVehicle 为当前登录用户添加一辆车辆
// 路由：POST /api/v1/vehicles
func AddUserVehicle(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从 Token 中解析 user_id
		userIDVal, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权，请先登录"})
			return
		}

		var userID uint
		switch v := userIDVal.(type) {
		case uint:
			userID = v
		case int:
			if v > 0 {
				userID = uint(v)
			}
		case int64:
			if v > 0 {
				userID = uint(v)
			}
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
			return
		}

		var req struct {
			LicensePlate string `json:"license_plate" binding:"required"`
			Brand        string `json:"brand"`
			Model        string `json:"model"`
			Color        string `json:"color"`
		}
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// 简单校验车牌号
		if req.LicensePlate == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "车牌号不能为空"})
			return
		}

		vehicle := model.Vehicle{
			UserID:       userID,
			LicensePlate: req.LicensePlate,
			Brand:        req.Brand,
			Model:        req.Model,
			Color:        req.Color,
			AddTime:      time.Now(),
		}

		if err := db.Create(&vehicle).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "添加车辆失败: " + err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message": "车辆添加成功",
			"vehicle": gin.H{
				"vehicle_id":    vehicle.VehicleID,
				"license_plate": vehicle.LicensePlate,
				"brand":         vehicle.Brand,
				"model":         vehicle.Model,
				"color":         vehicle.Color,
			},
		})
	}
}

// DeleteUserVehicle 删除当前登录用户的一辆车辆
// 路由：DELETE /api/v1/vehicles/:id
func DeleteUserVehicle(db *gorm.DB) gin.HandlerFunc {
	return func(c *gin.Context) {
		// 从 Token 中解析 user_id
		userIDVal, exists := c.Get("user_id")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "未授权，请先登录"})
			return
		}

		var userID uint
		switch v := userIDVal.(type) {
		case uint:
			userID = v
		case int:
			if v > 0 {
				userID = uint(v)
			}
		case int64:
			if v > 0 {
				userID = uint(v)
			}
		default:
			c.JSON(http.StatusBadRequest, gin.H{"error": "无效的用户ID"})
			return
		}

		vehicleIDStr := c.Param("id")
		if vehicleIDStr == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "车辆ID不能为空"})
			return
		}

		var vehicle model.Vehicle
		if err := db.Where("vehicle_id = ? AND user_id = ?", vehicleIDStr, userID).First(&vehicle).Error; err != nil {
			if err == gorm.ErrRecordNotFound {
				c.JSON(http.StatusNotFound, gin.H{"error": "车辆不存在"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "查询车辆失败"})
			return
		}

		if err := db.Delete(&vehicle).Error; err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "删除车辆失败"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"message":    "车辆删除成功",
			"vehicle_id": vehicle.VehicleID,
		})
	}
}

// AdminRegisterRequest 管理员注册请求结构体
type AdminRegisterRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required,min=6,max=20"`
	LotID    *uint  `json:"lot_id,omitempty"`
	Role     string `json:"role,omitempty"`
}

// AdminLoginRequest 管理员登录请求结构体
type AdminLoginRequest struct {
	Phone    string `json:"phone" binding:"required"`
	Password string `json:"password" binding:"required"`
}

// AdminRegisterController 管理员注册控制器
func AdminRegisterController(c *gin.Context) {
	var req AdminRegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 验证手机号格式
	if !isValidPhone(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "手机号格式无效"})
		return
	}

	// 检查手机号是否已注册（同时检查username和phone_number字段）
	var existingAdmin model.Admins
	result := inits.DB.Where("username = ? OR phone_number = ?", req.Phone, req.Phone).First(&existingAdmin)
	if result.Error == nil {
		c.JSON(http.StatusConflict, gin.H{"error": "手机号已注册"})
		return
	}

	// 加密密码
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "密码加密失败"})
		return
	}

	// 默认角色处理
	role := "lot_admin"
	if req.Role != "" {
		role = req.Role
	}

	// 创建管理员
	admin := model.Admins{
		Username:     req.Phone,
		PhoneNumber:  req.Phone, // 同时设置手机号字段
		PasswordHash: string(hashedPassword),
		Role:         role,
		LotID:        req.LotID,
		Status:       1, // 默认启用
		CreateTime:   time.Now(),
	}

	// 系统管理员不需要lot_id
	if role == "system" {
		admin.LotID = nil
	}

	// 保存管理员
	if err := inits.DB.Create(&admin).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "注册失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "注册成功",
		"admin":   admin,
	})
}

// AdminLoginController 管理员登录控制器
func AdminLoginController(c *gin.Context) {
	var req AdminLoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	// 验证手机号格式
	if !isValidPhone(req.Phone) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "手机号格式无效"})
		return
	}

	// 查找管理员 - 同时支持username和phone_number字段查询（兼容性）
	var admin model.Admins
	result := inits.DB.Where("username = ? OR phone_number = ?", req.Phone, req.Phone).First(&admin)
	if result.Error != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "用户不存在"})
		return
	}

	// 验证密码
	if err := bcrypt.CompareHashAndPassword([]byte(admin.PasswordHash), []byte(req.Password)); err != nil {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "密码错误"})
		return
	}

	// 检查账号状态
	if admin.Status != 1 {
		c.JSON(http.StatusForbidden, gin.H{"error": "账号已禁用"})
		return
	}

	// 生成JWT Token
	token, err := generateAdminToken(admin)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Token生成失败"})
		return
	}

	// 根据角色类型返回不同的成功响应[1,5](@ref)
	responseData := gin.H{
		"token":      token,
		"admin_info": admin,
	}

	switch admin.Role {
	case "system":
		responseData["message"] = "系统管理员登录成功"
		responseData["role"] = "system"
		c.JSON(http.StatusOK, responseData)
	case "lot_admin":
		responseData["message"] = "停车场管理员登录成功"
		responseData["role"] = "lot_admin"
		// 如果是停车场管理员，可以返回关联的停车场信息
		if admin.LotID != nil {
			responseData["lot_id"] = *admin.LotID
		}
		c.JSON(http.StatusOK, responseData)
	default:
		c.JSON(http.StatusForbidden, gin.H{"error": "未知管理员角色"})
		return
	}
}

// 生成JWT Token
func generateAdminToken(admin model.Admins) (string, error) {
	claims := jwt.MapClaims{
		"admin_id": admin.AdminID,
		"phone":    admin.Username,
		"role":     admin.Role,
		"lot_id":   admin.LotID,
		"exp":      time.Now().Add(time.Hour * 24).Unix(), // 24小时过期
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(inits.GetEnv("JWT_SECRET_ADMIN")))
}

// 手机号验证函数
func isValidPhone(phone string) bool {
	// 中国大陆手机号正则表达式
	pattern := `^1[3-9]\d{9}$`
	match, _ := regexp.MatchString(pattern, phone)
	return match
}
