package controller

import (
	"net/http"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

// ParkingSpaceOccupancyAnalysis 分析特定时间段内停车场车位的占用情况
func ParkingSpaceOccupancyAnalysis(c *gin.Context) {
	// 从中间件上下文中获取管理员角色和停车场信息
	roleVal, _ := c.Get("role")
	role, _ := roleVal.(string)

	var lotIDUint uint
	if lotID, exists := c.Get("lot_id"); exists && lotID != nil {
		if v, ok := lotID.(uint); ok {
			lotIDUint = v
		} else {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "停车场ID格式错误"})
			return
		}
	}

	// 如果是系统管理员且未绑定具体停车场，则不允许直接访问该接口
	//（当前实现仅支持针对单个停车场的分析）
	if lotIDUint == 0 || role != "lot_admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限查询或未分配停车场"})
		return
	}

	// 获取查询参数
	startTimeStr := c.Query("start_time")
	endTimeStr := c.Query("end_time")

	startTime, err := time.Parse(time.RFC3339, startTimeStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "开始时间格式无效，请使用RFC3339格式（如：2023-10-18T10:00:00Z）"})
		return
	}

	endTime, err := time.Parse(time.RFC3339, endTimeStr)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "结束时间格式无效，请使用RFC3339格式（如：2023-10-18T20:00:00Z）"})
		return
	}

	// 验证时间范围合理性
	if endTime.Before(startTime) {
		c.JSON(http.StatusBadRequest, gin.H{"error": "结束时间不能早于开始时间"})
		return
	}

	// 查询车位占用情况
	occupancyStats, err := getParkingOccupancyStats(lotIDUint, startTime, endTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "数据分析失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "停车场分析成功",
		"data":    occupancyStats,
		"metadata": gin.H{
			"lot_id":          lotIDUint,
			"start_time":      startTime.Format(time.RFC3339),
			"end_time":        endTime.Format(time.RFC3339),
			"time_range_days": endTime.Sub(startTime).Hours() / 24,
		},
	})
}

// getParkingOccupancyStats 封装统计分析逻辑
func getParkingOccupancyStats(lotID uint, startTime, endTime time.Time) (map[string]interface{}, error) {
	var occupancyStats = make(map[string]interface{})

	// 计算车位总数
	var totalSpaces int64
	err := inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ?", lotID).
		Count(&totalSpaces).Error
	if err != nil {
		return nil, err
	}
	occupancyStats["total_spaces"] = totalSpaces

	// 计算已占用车位数（在指定时间段内有停车记录的）
	var occupiedSpaces int64
	occupiedSubQuery := inits.DB.Model(&model.ParkingRecord{}).
		Select("DISTINCT space_id").
		Where("lot_id = ? AND entry_time <= ? AND (exit_time >= ? OR exit_time IS NULL)",
			lotID, endTime, startTime)

	err = inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND space_id IN (?)", lotID, occupiedSubQuery).
		Count(&occupiedSpaces).Error
	if err != nil {
		return nil, err
	}
	occupancyStats["occupied_spaces"] = occupiedSpaces

	// 计算预订车位数
	var reservedSpaces int64
	reserveSubQuery := inits.DB.Model(&model.ReservationOrder{}).
		Select("DISTINCT space_id").
		Where("lot_id = ? AND start_time <= ? AND end_time >= ? AND status = ?",
			lotID, endTime, startTime, 1) // 1-已预订

	err = inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND space_id IN (?)", lotID, reserveSubQuery).
		Count(&reservedSpaces).Error
	if err != nil {
		return nil, err
	}
	occupancyStats["reserved_spaces"] = reservedSpaces

	// 计算占用率
	occupancyRate := 0.0
	if totalSpaces > 0 {
		occupancyRate = float64(occupiedSpaces) / float64(totalSpaces) * 100
	}
	occupancyStats["occupancy_rate"] = occupancyRate

	// 计算总收入
	var incomeResult struct {
		TotalIncome float64
	}
	err = inits.DB.Model(&model.ParkingRecord{}).
		Select("COALESCE(SUM(fee_paid), 0) as total_income").
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Scan(&incomeResult).Error
	if err != nil {
		return nil, err
	}
	occupancyStats["total_income"] = incomeResult.TotalIncome

	// 计算平均日收入
	days := endTime.Sub(startTime).Hours() / 24
	avgDailyIncome := 0.0
	if days > 0 {
		avgDailyIncome = incomeResult.TotalIncome / days
	}
	occupancyStats["avg_daily_income"] = avgDailyIncome

	// 计算平均停车时长（小时）
	var avgDuration struct {
		AvgDuration float64
	}
	err = inits.DB.Model(&model.ParkingRecord{}).
		Select("COALESCE(AVG(duration_minutes), 0) as avg_duration").
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Scan(&avgDuration).Error
	if err != nil {
		return nil, err
	}
	occupancyStats["avg_parking_hours"] = avgDuration.AvgDuration / 60

	// 按车位类型统计（普通、充电）
	var occupancyByType []map[string]interface{}
	
	// 统计普通车位
	var normalStats struct {
		Total    int64
		Occupied int64
	}
	
	// 普通车位总数
	err = inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND space_type = ?", lotID, "普通").
		Count(&normalStats.Total).Error
	if err != nil {
		return nil, err
	}
	
	// 普通车位已占用数
	normalOccupiedSubQuery := inits.DB.Model(&model.ParkingRecord{}).
		Select("DISTINCT space_id").
		Where("lot_id = ? AND entry_time <= ? AND (exit_time >= ? OR exit_time IS NULL)",
			lotID, endTime, startTime)
	
	err = inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND space_type = ? AND space_id IN (?)", lotID, "普通", normalOccupiedSubQuery).
		Count(&normalStats.Occupied).Error
	if err != nil {
		return nil, err
	}
	
	occupancyByType = append(occupancyByType, map[string]interface{}{
		"space_type": "普通",
		"total":      normalStats.Total,
		"occupied":   normalStats.Occupied,
	})
	
	// 统计充电车位
	var chargingStats struct {
		Total    int64
		Occupied int64
	}
	
	// 充电车位总数
	err = inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND space_type = ?", lotID, "充电").
		Count(&chargingStats.Total).Error
	if err != nil {
		return nil, err
	}
	
	// 充电车位已占用数
	chargingOccupiedSubQuery := inits.DB.Model(&model.ParkingRecord{}).
		Select("DISTINCT space_id").
		Where("lot_id = ? AND entry_time <= ? AND (exit_time >= ? OR exit_time IS NULL)",
			lotID, endTime, startTime)
	
	err = inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND space_type = ? AND space_id IN (?)", lotID, "充电", chargingOccupiedSubQuery).
		Count(&chargingStats.Occupied).Error
	if err != nil {
		return nil, err
	}
	
	occupancyByType = append(occupancyByType, map[string]interface{}{
		"space_type": "充电",
		"total":      chargingStats.Total,
		"occupied":   chargingStats.Occupied,
	})
	
	// 确保occupancy字段被添加到返回结果中
	occupancyStats["occupancy"] = occupancyByType
	
	// 调试日志：确保occupancy数组被正确添加
	if len(occupancyByType) == 0 {
		// 如果数组为空，至少添加默认值
		occupancyByType = append(occupancyByType, map[string]interface{}{
			"space_type": "普通",
			"total":      0,
			"occupied":   0,
		})
		occupancyByType = append(occupancyByType, map[string]interface{}{
			"space_type": "充电",
			"total":      0,
			"occupied":   0,
		})
		occupancyStats["occupancy"] = occupancyByType
	}

	return occupancyStats, nil
}

// ViolationAnalysis 统计和分析违规停车行为的数量及其处理情况
func ViolationAnalysis(c *gin.Context) {
	// 直接从中间件设置的上下文中获取管理员信息
	roleVal, _ := c.Get("role")
	role, _ := roleVal.(string)

	lotID, exists := c.Get("lot_id")
	if !exists || lotID == nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限查询或未分配停车场"})
		return
	}

	// 类型断言，确保lotID是uint类型
	lotIDUint, ok := lotID.(uint)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "停车场ID格式错误"})
		return
	}

	// 违规分析同样只允许停车场管理员查询自己停车场的数据
	if role != "lot_admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限查询或未分配停车场"})
		return
	}

	// 获取查询参数（年份和月份）
	yearStr := c.Query("year")
	monthStr := c.Query("month")

	// 默认当前年月
	now := time.Now()
	year := now.Year()
	month := int(now.Month())

	if yearStr != "" {
		if y, err := strconv.Atoi(yearStr); err == nil && y > 2000 && y <= now.Year() {
			year = y
		}
	}

	if monthStr != "" {
		if m, err := strconv.Atoi(monthStr); err == nil && m >= 1 && m <= 12 {
			month = m
		}
	}

	// 计算时间范围
	startTime := time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)
	endTime := startTime.AddDate(0, 1, 0).Add(-time.Nanosecond)

	// 获取违规统计数据
	violationStats, err := getViolationStats(lotIDUint, startTime, endTime)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "违规数据分析失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "违规分析成功",
		"data":    violationStats,
		"metadata": gin.H{
			"lot_id":     lotIDUint,
			"year":       year,
			"month":      month,
			"start_time": startTime.Format(time.RFC3339),
			"end_time":   endTime.Format(time.RFC3339),
		},
	})
}

// getViolationStats 获取违规统计数据
func getViolationStats(lotID uint, startTime, endTime time.Time) (map[string]interface{}, error) {
	var stats = make(map[string]interface{})

	// 1. 统计总违规次数（包括所有类型的违规）
	// 先统计有停车记录关联的违规
	var violationsWithRecord int64
	err := inits.DB.Model(&model.ViolationRecord{}).
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Count(&violationsWithRecord).Error
	if err != nil {
		return nil, err
	}
	
	// 统计未支付停车费违规（通过车辆关联到该停车场的停车记录）
	var unpaidParkingViolationsCount int64
	err = inits.DB.Model(&model.ViolationRecord{}).
		Joins("JOIN vehicle ON violation_record.vehicle_id = vehicle.vehicle_id").
		Joins("JOIN parking_record ON vehicle.vehicle_id = parking_record.vehicle_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_type = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, "未支付停车费", startTime, endTime).
		Distinct("violation_record.violation_id").
		Count(&unpaidParkingViolationsCount).Error
	if err != nil {
		// 如果查询失败，设为0（保守策略）
		unpaidParkingViolationsCount = 0
	}
	
	totalViolations := violationsWithRecord + unpaidParkingViolationsCount
	stats["total_violations"] = totalViolations

	// 2. 按违规类型统计（确保包含三种类型：超时停车、预订未使用、未支付停车费）
	// 先统计所有违规类型
	var violationsByTypeRaw []struct {
		ViolationType string
		Count         int64
	}
	
	// 查询有停车记录关联的违规（超时停车、预订未使用等）
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select("violation_type, COUNT(*) as count").
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Group("violation_type").
		Scan(&violationsByTypeRaw).Error
	if err != nil {
		return nil, err
	}
	
	// 查询未支付停车费违规（通过车辆关联到该停车场的停车记录）
	// 注意：未支付停车费的record_id可能为0，需要通过车辆关联停车场
	var unpaidParkingViolations int64
	err = inits.DB.Model(&model.ViolationRecord{}).
		Joins("JOIN vehicle ON violation_record.vehicle_id = vehicle.vehicle_id").
		Joins("JOIN parking_record ON vehicle.vehicle_id = parking_record.vehicle_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_type = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, "未支付停车费", startTime, endTime).
		Distinct("violation_record.violation_id").
		Count(&unpaidParkingViolations).Error
	if err != nil {
		// 如果查询失败，设为0（保守策略）
		unpaidParkingViolations = 0
	}
	
	// 构建标准化的违规类型统计（确保三种类型都存在）
	violationsByType := make([]map[string]interface{}, 0)
	typeCountMap := make(map[string]int64)
	
	// 将查询结果放入map
	for _, item := range violationsByTypeRaw {
		typeCountMap[item.ViolationType] = item.Count
	}
	
	// 添加未支付停车费统计
	if unpaidParkingViolations > 0 {
		typeCountMap["未支付停车费"] = unpaidParkingViolations
	}
	
	// 确保三种类型都存在（即使为0）
	requiredTypes := []string{"超时停车", "预订未使用", "未支付停车费"}
	for _, vType := range requiredTypes {
		count := typeCountMap[vType]
		if count == 0 {
			// 如果该类型没有数据，也要显示为0
			count = 0
		}
		violationsByType = append(violationsByType, map[string]interface{}{
			"violation_type": vType,
			"count":          count,
		})
	}
	
	stats["violations_by_type"] = violationsByType

	// 3. 按处理状态统计（包括所有类型的违规）
	// 先统计有停车记录关联的违规状态
	var violationsByStatusRaw []struct {
		Status int8
		Count  int64
	}
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select("violation_record.status, COUNT(*) as count").
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Group("violation_record.status").
		Scan(&violationsByStatusRaw).Error
	if err != nil {
		return nil, err
	}
	
	// 统计未支付停车费违规的状态（通过车辆关联到该停车场的停车记录）
	var unpaidStatusStats []struct {
		Status int8
		Count  int64
	}
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select("violation_record.status, COUNT(DISTINCT violation_record.violation_id) as count").
		Joins("JOIN vehicle ON violation_record.vehicle_id = vehicle.vehicle_id").
		Joins("JOIN parking_record ON vehicle.vehicle_id = parking_record.vehicle_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_type = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, "未支付停车费", startTime, endTime).
		Group("violation_record.status").
		Scan(&unpaidStatusStats).Error
	if err != nil {
		// 如果查询失败，忽略未支付停车费的状态统计
		unpaidStatusStats = []struct {
			Status int8
			Count  int64
		}{}
	}
	
	// 合并状态统计
	statusMap := make(map[int8]int64)
	for _, item := range violationsByStatusRaw {
		statusMap[item.Status] += item.Count
	}
	for _, item := range unpaidStatusStats {
		statusMap[item.Status] += item.Count
	}
	
	// 构建标准化的状态统计（确保两种状态都存在）
	violationsByStatus := make([]map[string]interface{}, 0)
	// 确保显示两种状态：0-未处理，1-已处理
	for _, status := range []int8{0, 1} {
		count := statusMap[status]
		violationsByStatus = append(violationsByStatus, map[string]interface{}{
			"status": status,
			"count":  count,
		})
	}
	
	stats["violations_by_status"] = violationsByStatus

	// 4. 统计罚款总额
	var totalFines struct {
		TotalFines float64
	}
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select("COALESCE(SUM(fine_amount), 0) as total_fines").
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Scan(&totalFines).Error
	if err != nil {
		return nil, err
	}
	stats["total_fines"] = totalFines.TotalFines

	// 5. 统计已收罚款
	var collectedFines struct {
		CollectedFines float64
	}
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select("COALESCE(SUM(fine_amount), 0) as collected_fines").
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ? AND violation_record.status = ?",
			lotID, startTime, endTime, 1). // 状态1表示已处理
		Scan(&collectedFines).Error
	if err != nil {
		return nil, err
	}
	stats["collected_fines"] = collectedFines.CollectedFines

	// 6. 月度趋势分析（最近6个月）
	monthlyTrend, err := getViolationTrend(lotID, 6)
	if err != nil {
		return nil, err
	}
	stats["monthly_trend"] = monthlyTrend

	return stats, nil
}

// getViolationTrend 获取违规趋势数据
func getViolationTrend(lotID uint, months int) ([]map[string]interface{}, error) {
	var trend []map[string]interface{}

	now := time.Now()
	for i := months - 1; i >= 0; i-- {
		startTime := time.Date(now.Year(), now.Month()-time.Month(i), 1, 0, 0, 0, 0, time.Local)
		endTime := startTime.AddDate(0, 1, 0).Add(-time.Nanosecond)

		var monthlyStats struct {
			TotalViolations int64
			ProcessedCount  int64
			TotalFines      float64
		}

		// 总违规数
		err := inits.DB.Model(&model.ViolationRecord{}).
			Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
			Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
				lotID, startTime, endTime).
			Count(&monthlyStats.TotalViolations).Error
		if err != nil {
			return nil, err
		}

		// 已处理数
		err = inits.DB.Model(&model.ViolationRecord{}).
			Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
			Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ? AND violation_record.status = ?",
				lotID, startTime, endTime, 1).
			Count(&monthlyStats.ProcessedCount).Error
		if err != nil {
			return nil, err
		}

		// 罚款总额
		err = inits.DB.Model(&model.ViolationRecord{}).
			Select("COALESCE(SUM(fine_amount), 0) as total_fines").
			Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
			Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
				lotID, startTime, endTime).
			Scan(&monthlyStats.TotalFines).Error
		if err != nil {
			return nil, err
		}

		trend = append(trend, map[string]interface{}{
			"year_month":       startTime.Format("2006-01"),
			"total_violations": monthlyStats.TotalViolations,
			"processed_count":  monthlyStats.ProcessedCount,
			"processing_rate":  calculateRate(monthlyStats.ProcessedCount, monthlyStats.TotalViolations),
			"total_fines":      monthlyStats.TotalFines,
		})
	}

	return trend, nil
}

// GenerateReport 生成月度报告和年度报告
func GenerateReport(c *gin.Context) {
	// 直接从中间件设置的上下文中获取管理员信息
	roleVal, _ := c.Get("role")
	role, _ := roleVal.(string)

	lotID, exists := c.Get("lot_id")
	if !exists || lotID == nil {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限查询或未分配停车场"})
		return
	}

	// 类型断言
	lotIDUint, ok := lotID.(uint)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "停车场ID格式错误"})
		return
	}

	// 报表生成同样只允许停车场管理员查看自己停车场的数据
	if role != "lot_admin" {
		c.JSON(http.StatusForbidden, gin.H{"error": "无权限查询或未分配停车场"})
		return
	}

	// 获取查询参数
	yearStr := c.Query("year")
	monthStr := c.Query("month")
	reportType := c.Query("type") // "monthly" 或 "annual"

	// 参数验证
	if reportType != "monthly" && reportType != "annual" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "报告类型必须为 monthly 或 annual"})
		return
	}

	now := time.Now()
	year := now.Year()
	if yearStr != "" {
		if y, err := strconv.Atoi(yearStr); err == nil && y > 2000 && y <= now.Year() {
			year = y
		}
	}

	var startTime, endTime time.Time
	if reportType == "monthly" {
		month := int(now.Month())
		if monthStr != "" {
			if m, err := strconv.Atoi(monthStr); err == nil && m >= 1 && m <= 12 {
				month = m
			}
		}
		startTime = time.Date(year, time.Month(month), 1, 0, 0, 0, 0, time.Local)
		endTime = startTime.AddDate(0, 1, 0).Add(-time.Nanosecond)
	} else {
		// 年度报告
		startTime = time.Date(year, 1, 1, 0, 0, 0, 0, time.Local)
		endTime = time.Date(year, 12, 31, 23, 59, 59, 0, time.Local)
	}

	// 生成综合报告
	report, err := generateComprehensiveReport(lotIDUint, startTime, endTime, reportType)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "报告生成失败: " + err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"message": "报告生成成功",
		"report":  report,
		"metadata": gin.H{
			"lot_id":      lotIDUint,
			"report_type": reportType,
			"year":        year,
			"month":       monthStr,
			"start_time":  startTime.Format(time.RFC3339),
			"end_time":    endTime.Format(time.RFC3339),
		},
	})
}

// generateComprehensiveReport 生成综合报告
func generateComprehensiveReport(lotID uint, startTime, endTime time.Time, reportType string) (map[string]interface{}, error) {
	var report = make(map[string]interface{})

	// 基础信息
	report["report_type"] = reportType
	report["period"] = startTime.Format("2006-01-02") + " 至 " + endTime.Format("2006-01-02")
	report["generated_at"] = time.Now().Format(time.RFC3339)

	// 1. 停车数据统计
	parkingStats, err := getParkingStatsForReport(lotID, startTime, endTime)
	if err != nil {
		return nil, err
	}
	report["parking_statistics"] = parkingStats

	// 2. 违规数据统计
	violationStats, err := getViolationStatsForReport(lotID, startTime, endTime)
	if err != nil {
		return nil, err
	}
	report["violation_statistics"] = violationStats

	// 3. 收入统计
	revenueStats, err := getRevenueStats(lotID, startTime, endTime)
	if err != nil {
		return nil, err
	}
	report["revenue_statistics"] = revenueStats

	// 4. 车位使用率分析
	occupancyStats, err := getOccupancyStatsForReport(lotID, startTime, endTime)
	if err != nil {
		return nil, err
	}
	report["occupancy_statistics"] = occupancyStats

	// 5. 高峰时段分析
	peakHours, err := getPeakHoursAnalysis(lotID, startTime, endTime)
	if err != nil {
		return nil, err
	}
	report["peak_hours_analysis"] = peakHours

	return report, nil
}

// getParkingStatsForReport 获取停车统计数据用于报告
func getParkingStatsForReport(lotID uint, startTime, endTime time.Time) (map[string]interface{}, error) {
	var stats = make(map[string]interface{})

	// 总停车次数
	var totalParkings int64
	err := inits.DB.Model(&model.ParkingRecord{}).
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Count(&totalParkings).Error
	if err != nil {
		return nil, err
	}
	stats["total_parkings"] = totalParkings

	// 平均停车时长
	var avgDuration struct {
		AvgDuration float64
	}
	err = inits.DB.Model(&model.ParkingRecord{}).
		Select("COALESCE(AVG(duration_minutes), 0) as avg_duration").
		Where("lot_id = ? AND entry_time BETWEEN ? AND ? AND exit_time IS NOT NULL",
			lotID, startTime, endTime).
		Scan(&avgDuration).Error
	if err != nil {
		return nil, err
	}
	stats["avg_parking_hours"] = avgDuration.AvgDuration / 60

	// 不同车辆品牌的停车统计
	var vehicleBrandStats []struct {
		Brand string
		Count int64
	}
	err = inits.DB.Model(&model.ParkingRecord{}).
		Select("vehicle.brand, COUNT(*) as count").
		Joins("JOIN vehicle ON parking_record.vehicle_id = vehicle.vehicle_id").
		Where("parking_record.lot_id = ? AND parking_record.entry_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Group("vehicle.brand").
		Scan(&vehicleBrandStats).Error
	if err != nil {
		return nil, err
	}
	stats["vehicle_brand_distribution"] = vehicleBrandStats

	return stats, nil
}

// getViolationStatsForReport 获取违规统计数据用于报告
func getViolationStatsForReport(lotID uint, startTime, endTime time.Time) (map[string]interface{}, error) {
	var stats = make(map[string]interface{})

	// 总违规次数
	var totalViolations int64
	err := inits.DB.Model(&model.ViolationRecord{}).
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Count(&totalViolations).Error
	if err != nil {
		return nil, err
	}
	stats["total_violations"] = totalViolations

	// 违规处理率
	var processedViolations int64
	err = inits.DB.Model(&model.ViolationRecord{}).
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ? AND violation_record.status = ?",
			lotID, startTime, endTime, 1).
		Count(&processedViolations).Error
	if err != nil {
		return nil, err
	}
	stats["processed_violations"] = processedViolations
	stats["processing_rate"] = calculateRate(processedViolations, totalViolations)

	// 罚款统计
	var fineStats struct {
		TotalFines     float64
		CollectedFines float64
	}
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select(`
			COALESCE(SUM(fine_amount), 0) as total_fines,
			COALESCE(SUM(CASE WHEN status = 1 THEN fine_amount ELSE 0 END), 0) as collected_fines
		`).
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ?",
			lotID, startTime, endTime).
		Scan(&fineStats).Error
	if err != nil {
		return nil, err
	}
	stats["total_fines"] = fineStats.TotalFines
	stats["collected_fines"] = fineStats.CollectedFines
	stats["collection_rate"] = calculateRateFloat(fineStats.CollectedFines, fineStats.TotalFines)

	return stats, nil
}

// getRevenueStats 获取收入统计数据
func getRevenueStats(lotID uint, startTime, endTime time.Time) (map[string]interface{}, error) {
	var stats = make(map[string]interface{})

	// 停车费总收入
	var parkingIncome struct {
		TotalIncome float64
	}
	err := inits.DB.Model(&model.ParkingRecord{}).
		Select("COALESCE(SUM(fee_paid), 0) as total_income").
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Scan(&parkingIncome).Error
	if err != nil {
		return nil, err
	}
	stats["parking_income"] = parkingIncome.TotalIncome

	// 罚款收入
	var fineIncome struct {
		FineIncome float64
	}
	err = inits.DB.Model(&model.ViolationRecord{}).
		Select("COALESCE(SUM(fine_amount), 0) as fine_income").
		Joins("JOIN parking_record ON violation_record.record_id = parking_record.record_id").
		Where("parking_record.lot_id = ? AND violation_record.violation_time BETWEEN ? AND ? AND violation_record.status = ?",
			lotID, startTime, endTime, 1).
		Scan(&fineIncome).Error
	if err != nil {
		return nil, err
	}
	stats["fine_income"] = fineIncome.FineIncome
	stats["total_income"] = parkingIncome.TotalIncome + fineIncome.FineIncome

	// 月度收入趋势（如果是年度报告）
	if endTime.Sub(startTime).Hours()/24 > 90 { // 超过3个月，显示月度趋势
		monthlyRevenue, err := getMonthlyRevenueTrend(lotID, startTime, endTime)
		if err != nil {
			return nil, err
		}
		stats["monthly_revenue_trend"] = monthlyRevenue
	}

	return stats, nil
}

// getOccupancyStatsForReport 获取车位使用率统计用于报告
func getOccupancyStatsForReport(lotID uint, startTime, endTime time.Time) (map[string]interface{}, error) {
	var stats = make(map[string]interface{})

	// 获取总车位数
	var totalSpaces int64
	err := inits.DB.Model(&model.ParkingSpace{}).
		Where("lot_id = ? AND status = 1", lotID). // 只统计可用的车位
		Count(&totalSpaces).Error
	if err != nil {
		return nil, err
	}

	// 计算平均日使用率
	days := endTime.Sub(startTime).Hours() / 24
	if days < 1 {
		days = 1
	}

	// 估算总可能停车车次
	totalPossibleParkings := totalSpaces * int64(days)

	// 实际停车次数
	var actualParkings int64
	err = inits.DB.Model(&model.ParkingRecord{}).
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Count(&actualParkings).Error
	if err != nil {
		return nil, err
	}

	stats["total_spaces"] = totalSpaces
	stats["total_possible_parkings"] = totalPossibleParkings
	stats["actual_parkings"] = actualParkings
	stats["estimated_occupancy_rate"] = calculateRate(actualParkings, totalPossibleParkings)

	return stats, nil
}

// getPeakHoursAnalysis 获取高峰时段分析
func getPeakHoursAnalysis(lotID uint, startTime, endTime time.Time) ([]map[string]interface{}, error) {
	var peakHours []map[string]interface{}

	// 按小时统计停车次数
	var hourlyStats []struct {
		Hour  int
		Count int64
	}

	err := inits.DB.Model(&model.ParkingRecord{}).
		Select("HOUR(entry_time) as hour, COUNT(*) as count").
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Group("HOUR(entry_time)").
		Order("hour").
		Scan(&hourlyStats).Error
	if err != nil {
		return nil, err
	}

	for _, stat := range hourlyStats {
		peakHours = append(peakHours, map[string]interface{}{
			"hour":   stat.Hour,
			"count":  stat.Count,
			"period": getTimePeriod(stat.Hour),
		})
	}

	return peakHours, nil
}

// getMonthlyRevenueTrend 获取月度收入趋势
func getMonthlyRevenueTrend(lotID uint, startTime, endTime time.Time) ([]map[string]interface{}, error) {
	var monthlyTrend []map[string]interface{}

	// 按月统计收入
	var monthlyStats []struct {
		YearMonth string
		Income    float64
	}

	err := inits.DB.Model(&model.ParkingRecord{}).
		Select(`
			DATE_FORMAT(entry_time, '%Y-%m') as year_month,
			COALESCE(SUM(fee_paid), 0) as income
		`).
		Where("lot_id = ? AND entry_time BETWEEN ? AND ?", lotID, startTime, endTime).
		Group("DATE_FORMAT(entry_time, '%Y-%m')").
		Order("year_month").
		Scan(&monthlyStats).Error
	if err != nil {
		return nil, err
	}

	for _, stat := range monthlyStats {
		monthlyTrend = append(monthlyTrend, map[string]interface{}{
			"period": stat.YearMonth,
			"income": stat.Income,
		})
	}

	return monthlyTrend, nil
}

// 辅助函数
func calculateRate(numerator, denominator int64) float64 {
	if denominator == 0 {
		return 0
	}
	return float64(numerator) / float64(denominator) * 100
}

func calculateRateFloat(numerator, denominator float64) float64 {
	if denominator == 0 {
		return 0
	}
	return numerator / denominator * 100
}

func getTimePeriod(hour int) string {
	switch {
	case hour >= 6 && hour < 10:
		return "早晨高峰"
	case hour >= 10 && hour < 14:
		return "上午时段"
	case hour >= 14 && hour < 17:
		return "下午时段"
	case hour >= 17 && hour < 20:
		return "晚间高峰"
	default:
		return "夜间时段"
	}
}
