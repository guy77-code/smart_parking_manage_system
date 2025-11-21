package controller

import (
	"context"
	"encoding/json"
	"net/http"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// AddParkingSpace 添加新停车位
// 功能：接收JSON格式的车位数据，验证停车场有效性后存入数据库
// 参数：通过请求体JSON绑定到model.ParkingSpace结构体
// 返回：成功添加的车位信息或错误提示
func AddParkingSpace(c *gin.Context) {
	var space model.ParkingSpace

	// 1. 绑定请求体JSON到结构体
	if err := c.ShouldBindJSON(&space); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数无效"})
		return
	}

	// 2. 验证停车场ID有效性
	var lot model.ParkingLot
	if err := inits.DB.First(&lot, space.LotID).Error; err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的停车场ID"})
		return
	}

	// 3. 设置最后更新时间
	space.LastUpdate = time.Now()

	// 4. 创建数据库记录
	if err := inits.DB.Create(&space).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据库插入失败"})
		return
	}
	//预加载Lot关联数据以返回完整信息
	if err := inits.DB.Preload("Lot").First(&space, space.SpaceID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据查询失败"})
		return
	}

	// 5. 返回成功响应
	c.JSON(http.StatusOK, gin.H{
		"message": "车位添加成功",
		"data":    space,
	})
}

// UpdateSpaceStatus 更新车位状态（数据库+Redis缓存）
// 功能：根据ID查找车位，更新状态字段，同步更新Redis缓存
// 参数：车位ID（URL路径参数），状态更新字段（JSON请求体）
// 返回：更新后的车位信息或错误提示
func UpdateSpaceStatus(c *gin.Context) {
	// 1. 从URL路径获取车位ID
	id := c.Param("id")

	// 2. 查询数据库获取车位记录
	var space model.ParkingSpace
	if err := inits.DB.First(&space, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到该车位"})
		return
	}

	// 3. 定义请求体结构（仅接收需要更新的字段）
	var req struct {
		Status     *int8 `json:"status"`      // 状态字段指针，允许nil值
		IsOccupied *int8 `json:"is_occupied"` // 占用状态指针
		IsReserved *int8 `json:"is_reserved"` // 预订状态指针
	}

	// 4. 绑定JSON请求体
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求体无效"})
		return
	}

	// 5. 构建更新字段映射
	updates := map[string]interface{}{
		"last_update": time.Now(), // 强制更新最后更新时间
	}

	// 6. 条件更新字段（仅更新非nil字段）
	if req.Status != nil {
		updates["status"] = *req.Status
		space.Status = *req.Status // 更新内存对象用于后续缓存
	}
	if req.IsOccupied != nil {
		updates["is_occupied"] = *req.IsOccupied
		space.IsOccupied = *req.IsOccupied
	}
	if req.IsReserved != nil {
		updates["is_reserved"] = *req.IsReserved
		space.IsReserved = *req.IsReserved
	}

	// 7. 执行数据库更新（使用Updates确保只更新指定字段）
	if err := inits.DB.Model(&space).Updates(updates).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据库更新失败"})
		return
	}

	// 8. 异步更新Redis缓存（避免阻塞主请求）
	go func(space model.ParkingSpace) {
		// 创建带超时的context（防止Redis操作无限期阻塞）
		ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer cancel() // 确保释放资源

		// 构建缓存键名（格式：parking_space:{id}）
		key := "parking_space:" + strconv.Itoa(int(space.SpaceID))

		// 序列化车位数据
		data, err := json.Marshal(space)
		if err != nil {
			return // 序列化失败时放弃缓存更新
		}

		// 设置缓存（5分钟过期时间，平衡数据实时性和缓存有效性）
		inits.RedisClient.Set(ctx, key, data, 5*time.Minute)
	}(space) // 传递当前space对象的副本

	// 重新查询以获取关联的停车场信息
	if err := inits.DB.Preload("Lot").First(&space, space.SpaceID).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据查询失败"})
		return
	}

	// 9. 返回成功响应
	c.JSON(http.StatusOK, gin.H{
		"message": "车位状态更新成功",
		"data":    space,
	})
}

// GetSpacesByLotID 获取指定停车场的所有车位
// 功能：查询特定停车场下的所有车位信息（支持预加载停车场详情）
// 参数：停车场ID（URL路径参数）
// 返回：车位列表或错误提示
func GetSpacesByLotID(c *gin.Context) {
	// 1. 从URL路径获取停车场ID
	lotID := c.Param("lot_id")

	// 2. 验证ID格式（必须是数字）
	if _, err := strconv.Atoi(lotID); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "无效的停车场ID"})
		return
	}

	// 3. 查询数据库（使用预加载减少N+1查询）
	var spaces []model.ParkingSpace
	err := inits.DB.
		Preload("Lot"). // 预加载关联的停车场信息
		Where("lot_id = ?", lotID).
		Find(&spaces).Error

	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据库查询失败"})
		return
	}

	// 4. 返回查询结果
	c.JSON(http.StatusOK, gin.H{
		"message": "查询成功",
		"count":   len(spaces), // 返回记录数量便于前端处理
		"data":    spaces,
	})
}
