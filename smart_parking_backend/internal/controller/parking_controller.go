package controller

import (
	"net/http"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"time"

	"github.com/gin-gonic/gin"
)

// 添加新停车场（管理员）
func AddParkingLot(c *gin.Context) {
	var lot model.ParkingLot

	// 绑定 JSON 请求体
	if err := c.ShouldBindJSON(&lot); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求参数无效"})
		return
	}

	// 初始化时间字段（如果未由前端传入）
	lot.CreateTime = time.Now()
	lot.UpdateTime = time.Now()

	// 保存到数据库
	if err := inits.DB.Create(&lot).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据库错误"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "停车场添加成功",
		"data":    lot,
	})
}

// 获取所有停车场及其车位信息
func GetAllParkingLots(c *gin.Context) {
	var lots []model.ParkingLot

	if err := inits.DB.Preload("Spaces").Find(&lots).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据库查询错误"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "查询成功",
		"data":    lots,
	})
}

// 根据ID获取停车场详情及车位信息
func GetParkingLotByID(c *gin.Context) {
	id := c.Param("id")

	var lot model.ParkingLot
	if err := inits.DB.Preload("Spaces").First(&lot, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到该停车场"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "查询成功",
		"data":    lot,
	})
}

// 更新停车场信息
func UpdateParkingLot(c *gin.Context) {
	id := c.Param("id")

	var lot model.ParkingLot
	if err := inits.DB.First(&lot, id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "未找到该停车场"})
		return
	}

	var req model.ParkingLot
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "请求体无效"})
		return
	}

	req.UpdateTime = time.Now()

	// 使用 Model().Updates() 只更新非零字段
	if err := inits.DB.Model(&lot).Updates(req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "更新失败"})
		return
	}

	inits.DB.First(&lot, id)

	c.JSON(http.StatusOK, gin.H{
		"message": "停车场信息更新成功",
		"data":    lot,
	})
}

// 删除停车场（自动级联删除车位）
func DeleteParkingLot(c *gin.Context) {
	id := c.Param("id")

	if err := inits.DB.Delete(&model.ParkingLot{}, id).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "删除失败"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "停车场删除成功（关联车位已自动删除）",
	})
}
