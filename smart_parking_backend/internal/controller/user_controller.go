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

		c.JSON(http.StatusOK, gin.H{
			"total":     total,
			"page":      page,
			"page_size": pageSize,
			"records":   payments,
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
