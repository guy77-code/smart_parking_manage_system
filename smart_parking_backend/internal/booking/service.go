package booking

import (
	"errors"
	"fmt"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"time"
)

// Service 层：封装停车位预订与支付的核心业务逻辑
type Service struct {
	repo *Repository
}

// NewService 创建 Service 实例
func NewService(repo *Repository) *Service {
	return &Service{repo: repo}
}

// ==================== 预订流程 ====================
// CreateBooking 用户预订车位
// 流程：查找可用车位 → 创建预订订单 → 标记车位为已预订
func (s *Service) CreateBooking(userID, vehicleID, lotID uint, start, end time.Time, spaceType string) (*model.ReservationOrder, error) {
	space, err := s.repo.FindAvailableSlot(lotID, spaceType)
	if err != nil {
		return nil, errors.New("当前停车场无可用车位")
	}
	if !end.After(start) {
		return nil, errors.New("结束时间必须晚于开始时间")
	}
	duration := int(end.Sub(start).Minutes())
	if duration <= 0 {
		return nil, errors.New("预订时间无效")
	}
	// 确保使用Asia/Shanghai时区
	loc, err := time.LoadLocation("Asia/Shanghai")
	if err != nil {
		loc = time.Local
	}
	now := time.Now().In(loc)
	
	resCode := fmt.Sprintf("RES-%d-%d", userID, now.UnixNano())
	order := &model.ReservationOrder{
		UserID:          userID,
		VehicleID:       vehicleID,
		LotID:           lotID,
		SpaceID:         space.SpaceID,
		StartTime:       start.In(loc), // 确保使用Asia/Shanghai时区
		EndTime:         end.In(loc),   // 确保使用Asia/Shanghai时区
		DurationMinutes: duration,
		BookingTime:     now,            // 使用Asia/Shanghai时区的当前时间
		Status:          1,
		PaymentStatus:   0,
		ReservationCode: resCode,
	}
	if err := s.repo.CreateBooking(order); err != nil {
		return nil, err
	}
	if err := s.repo.MarkSlotAsBooked(space.SpaceID, true); err != nil {
		return order, errors.New("车位状态更新失败")
	}
	return order, nil
}

// ==================== 支付流程 ====================
// CreatePendingPayment: 在生成支付跳转时，先在 DB 中创建一条“待支付”记录
func (s *Service) CreatePendingPayment(orderID uint, userID uint, amount float64, method string, transactionNo string) (*model.PaymentRecord, error) {
	// 检查订单是否存在
	order, err := s.repo.GetBookingByID(orderID)
	if err != nil {
		return nil, errors.New("订单不存在")
	}
	// 不能为已支付订单创建 pending
	if order.PaymentStatus == 1 {
		return nil, errors.New("订单已支付")
	}
	now := time.Now()
	p := &model.PaymentRecord{
		OrderID:       orderID,
		UserID:        userID,
		Amount:        amount,
		Method:        method,
		TransactionNo: transactionNo,
		PaymentStatus: 0, // 待支付
		CreateTime:    now,
	}
	if err := s.repo.CreatePayment(p); err != nil {
		return nil, err
	}
	return p, nil
}

// PayBooking: 当收到支付回调时调用此方法，若存在 pending 记录则更新；否则创建新记录
func (s *Service) PayBooking(orderID uint, userID uint, amount float64, method, transactionNo string) (*model.PaymentRecord, error) {
	order, err := s.repo.GetBookingByID(orderID)
	if err != nil {
		return nil, errors.New("订单不存在")
	}
	if order.PaymentStatus == 1 {
		return nil, errors.New("订单已支付")
	}
	if order.Status == 0 {
		return nil, errors.New("订单已取消，无法支付")
	}

	// 尝试查找 pending 支付记录
	pending, err := s.repo.FindPendingPaymentByOrder(orderID)
	if err != nil {
		return nil, err
	}

	now := time.Now()
	if pending != nil {
		// 更新 pending 记录为已支付
		pending.Amount = amount
		pending.Method = method
		pending.TransactionNo = transactionNo
		pending.PaymentStatus = 1
		pending.PayTime = &now
		if err := s.repo.UpdatePayment(pending); err != nil {
			return nil, err
		}
		// 更新订单
		order.PaymentStatus = 1
		order.Status = 2
		order.PaidFee = amount
		if err := s.repo.UpdateBooking(order); err != nil {
			return pending, errors.New("支付成功但订单更新失败")
		}
		return pending, nil
	}

	// 没有 pending，创建新的支付记录并写入
	payment := &model.PaymentRecord{
		OrderID:       order.OrderID,
		UserID:        userID,
		Amount:        amount,
		Method:        method,
		TransactionNo: transactionNo,
		PaymentStatus: 1,
		PayTime:       &now,
	}
	if err := s.repo.CreatePayment(payment); err != nil {
		return nil, err
	}
	order.PaymentStatus = 1
	order.Status = 2
	order.PaidFee = amount
	if err := s.repo.UpdateBooking(order); err != nil {
		return payment, errors.New("支付成功但订单更新失败")
	}
	return payment, nil
}

// ==================== 取消预订 ====================
func (s *Service) CancelBooking(orderID uint) error {
	order, err := s.repo.GetBookingByID(orderID)
	if err != nil {
		return errors.New("订单不存在")
	}
	if order.PaymentStatus == 1 {
		return errors.New("已支付订单请申请退款")
	}
	order.Status = 0
	order.PaymentStatus = 0
	if err := s.repo.UpdateBooking(order); err != nil {
		return err
	}
	if err := s.repo.MarkSlotAsBooked(order.SpaceID, false); err != nil {
		return errors.New("订单取消成功，但车位释放失败")
	}
	return nil
}

// ==================== 查询功能 ===================
func (s *Service) GetUserBookings(userID uint) ([]model.ReservationOrder, error) {
	return s.repo.FindBookingsByUser(userID)
}

func (s *Service) GetBookingDetail(orderID uint) (*model.ReservationOrder, error) {
	return s.repo.GetBookingByID(orderID)
}

// ==================== 检查和更新超时预订 ====================
// CheckAndUpdateExpiredBookings 检查并更新超时的预订记录
// 将已超过结束时间且未完成的预订状态更新为已取消
func (s *Service) CheckAndUpdateExpiredBookings() (int, error) {
	now := time.Now()
	var expiredBookings []model.ReservationOrder

	// 查找所有已超过结束时间且状态为已预订(1)或使用中(2)的预订
	err := inits.DB.
		Where("end_time < ?", now).
		Where("status IN (?)", []int8{1, 2}). // 1-已预订, 2-使用中
		Where("actual_end_time IS NULL").     // 未实际结束
		Find(&expiredBookings).Error

	if err != nil {
		return 0, err
	}

	count := 0
	for _, booking := range expiredBookings {
		// 更新预订状态为已取消
		actualEndTime := now
		booking.Status = 0 // 0-已取消
		booking.ActualEndTime = &actualEndTime

		if err := s.repo.UpdateBooking(&booking); err != nil {
			continue // 如果更新失败，跳过这条记录
		}

		// 释放车位
		if err := s.repo.MarkSlotAsBooked(booking.SpaceID, false); err != nil {
			// 记录错误但不影响主流程
			fmt.Printf("释放车位失败: space_id=%d, error=%v\n", booking.SpaceID, err)
		}

		count++
	}

	return count, nil
}
