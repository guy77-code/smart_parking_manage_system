package payment

import (
	"errors"
	"fmt"
	"net/url"
	"smart_parking_backend/internal/booking"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"time"

	"gorm.io/gorm"
)

type Service struct {
	bookingSvc *booking.Service
	cfg        *Config
	// 模拟支付页面基础地址（如果在 Config 中未配置，使用默认）
	simulateBase string
}

func NewService(bookingSvc *booking.Service, cfg *Config) *Service {
	simHost := "http://127.0.0.1:8081/simulate_payment" // 默认模拟支付页面地址（QT 可监听此地址或替换）
	if cfg != nil && cfg.SimulateHost != "" {
		simHost = cfg.SimulateHost
	}
	return &Service{
		bookingSvc:   bookingSvc,
		cfg:          cfg,
		simulateBase: simHost,
	}
}

func (s *Service) Config() *Config {
	return s.cfg
}

// CreatePayment 统一入口：创建 pending 支付记录并返回模拟支付跳转 URL
// typ: "reservation" | "parking" | "violation"
// method: "alipay" | "wechat"
// amountPtr: 可选，若提供则使用该金额；否则从 DB 查出应付金额
// 返回 redirectURL, paymentID, error
func (s *Service) CreatePayment(orderID uint, typ, method string, amountPtr *float64) (string, uint64, error) {
	if method != "alipay" && method != "wechat" {
		return "", 0, errors.New("不支持的支付方式")
	}

	switch typ {
	case "reservation":
		return s.createReservationPayment(orderID, method, amountPtr)
	case "parking":
		return s.createParkingPayment(orderID, method, amountPtr)
	case "violation":
		return s.createViolationPayment(orderID, method, amountPtr)
	default:
		return "", 0, errors.New("未知的订单类型")
	}
}

// ----- reservation -----
func (s *Service) createReservationPayment(orderID uint, method string, amountPtr *float64) (string, uint64, error) {
	// 使用 bookingSvc 获取订单
	order, err := s.bookingSvc.GetBookingDetail(orderID)
	if err != nil {
		return "", 0, errors.New("订单不存在")
	}
	if order.PaymentStatus == 1 {
		return "", 0, errors.New("订单已支付")
	}
	if order.Status == 0 {
		return "", 0, errors.New("订单已取消")
	}

	amount := order.TotalFee
	if amountPtr != nil {
		amount = *amountPtr
	}
	if amount <= 0 {
		return "", 0, errors.New("订单金额为0，请确认金额")
	}

	// 创建 pending 支付（通过 bookingSvc 的方法以确保行为一致）
	payment, err := s.bookingSvc.CreatePendingPayment(order.OrderID, order.UserID, amount, method, "")
	if err != nil {
		return "", 0, err
	}

	// 构建模拟页面 URL（前端展示）
	// 模拟链接带上 provider, payment_id, return_to (可选)
	u := fmt.Sprintf("%s?provider=%s&payment_id=%d", s.simulateBase, url.QueryEscape(method), payment.PaymentID)
	return u, payment.PaymentID, nil
}

// ----- parking -----
func (s *Service) createParkingPayment(recordID uint, method string, amountPtr *float64) (string, uint64, error) {
	// 查找 ParkingRecord
	var record model.ParkingRecord
	if err := inits.DB.First(&record, recordID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", 0, errors.New("停车记录不存在")
		}
		return "", 0, errors.New("查询停车记录失败")
	}

	amount := record.FeeCalculated
	if amountPtr != nil {
		amount = *amountPtr
	}
	if amount <= 0 {
		return "", 0, errors.New("停车费用为0，请确认金额")
	}

	// 创建 pending payment record 直接写入 payment_record 表
	now := time.Now()
	p := &model.PaymentRecord{
		OrderID:       record.RecordID, // 在表结构里 OrderID 字段复用为关联 ID（reservation/parking/violation）
		UserID:        record.UserID,
		Amount:        amount,
		Method:        method,
		TransactionNo: "",
		PaymentStatus: 0, // 待支付
		CreateTime:    now,
	}
	if err := inits.DB.Create(p).Error; err != nil {
		return "", 0, errors.New("创建支付记录失败")
	}
	u := fmt.Sprintf("%s?provider=%s&payment_id=%d", s.simulateBase, url.QueryEscape(method), p.PaymentID)
	return u, p.PaymentID, nil
}

// ----- violation -----
func (s *Service) createViolationPayment(violationID uint, method string, amountPtr *float64) (string, uint64, error) {
	var vio model.ViolationRecord
	if err := inits.DB.First(&vio, violationID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", 0, errors.New("违规记录不存在")
		}
		return "", 0, errors.New("查询违规记录失败")
	}

	if vio.Status == 1 {
		return "", 0, errors.New("罚款已处理")
	}

	amount := vio.FineAmount
	if amountPtr != nil {
		amount = *amountPtr
	}
	if amount <= 0 {
		return "", 0, errors.New("罚款金额为0，请确认金额")
	}

	now := time.Now()
	p := &model.PaymentRecord{
		OrderID:       vio.ViolationID, // reuse OrderID field
		UserID:        vio.UserID,
		Amount:        amount,
		Method:        method,
		TransactionNo: "",
		PaymentStatus: 0,
		CreateTime:    now,
	}
	if err := inits.DB.Create(p).Error; err != nil {
		return "", 0, errors.New("创建支付记录失败")
	}

	u := fmt.Sprintf("%s?provider=%s&payment_id=%d", s.simulateBase, url.QueryEscape(method), p.PaymentID)
	return u, p.PaymentID, nil
}

// ----- 回调处理 -----
// HandleNotify 处理模拟支付回调：根据 payment_id 更新 payment_record 并更新对应业务表（reservation/parking/violation）
func (s *Service) HandleNotify(paymentID uint64, amount float64, provider, transactionNo string) (*model.PaymentRecord, error) {
	// 查找 payment_record
	var p model.PaymentRecord
	if err := inits.DB.First(&p, paymentID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("支付记录不存在")
		}
		return nil, errors.New("查询支付记录失败")
	}

	// 如果已支付，直接返回
	if p.PaymentStatus == 1 {
		return &p, nil
	}

	// 更新 payment_record
	now := time.Now()
	p.PaymentStatus = 1
	p.TransactionNo = transactionNo
	p.Method = provider // ensure provider saved
	p.Amount = amount
	p.PayTime = &now

	if err := inits.DB.Save(&p).Error; err != nil {
		return nil, errors.New("更新支付记录失败")
	}

	// 尝试根据 OrderID 在 reservation 表中查找 -- 如果存在，使用 bookingSvc 进行后续处理
	// 注意：ReservationOrder 的 OrderID 与 PaymentRecord.OrderID 一致
	var reservation model.ReservationOrder
	if err := inits.DB.First(&reservation, p.OrderID).Error; err == nil {
		// 有 reservation 记录 -> 使用 bookingSvc.PayBooking 以保持一致行为
		// bookingSvc.PayBooking 会更新 payment_record（如果存在 pending）以及更新订单状态
		_, err := s.bookingSvc.PayBooking(reservation.OrderID, p.UserID, amount, provider, transactionNo)
		if err != nil {
			// 记录已更新为支付，但 bookingSvc 更新失败：回滚并告知（这里无法回滚 payment_record 更新，记录仍为已支付）
			return &p, fmt.Errorf("支付记录已更新，但订单更新失败: %w", err)
		}
		return &p, nil
	}

	// 若不是 reservation，则尝试 parking_record
	var park model.ParkingRecord
	if err := inits.DB.First(&park, p.OrderID).Error; err == nil {
		// 更新停车记录的支付相关字段
		park.PaymentStatus = 1
		park.FeePaid = amount
		if err := inits.DB.Save(&park).Error; err != nil {
			return &p, errors.New("更新停车记录失败")
		}
		return &p, nil
	}

	// 再尝试 violation_record
	var vio model.ViolationRecord
	if err := inits.DB.First(&vio, p.OrderID).Error; err == nil {
		// 更新违规记录状态为已处理/已支付
		vio.Status = 1
		if err := inits.DB.Save(&vio).Error; err != nil {
			return &p, errors.New("更新违规记录失败")
		}
		return &p, nil
	}

	// 如果没找到任何关联表，返回已支付的 payment 但告知未找到关联业务记录
	return &p, errors.New("支付已记录，但未找到关联的业务记录（reservation/parking/violation）")
}
