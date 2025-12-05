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
	// 先检查是否已有pending支付记录
	var existingPayment model.PaymentRecord
	if err := inits.DB.Where("order_id = ? AND payment_status = 0", recordID).First(&existingPayment).Error; err == nil {
		// 如果已有pending支付记录，直接返回
		u := fmt.Sprintf("%s?provider=%s&payment_id=%d", s.simulateBase, url.QueryEscape(method), existingPayment.PaymentID)
		return u, existingPayment.PaymentID, nil
	}

	// 查找 ParkingRecord
	var record model.ParkingRecord
	if err := inits.DB.First(&record, recordID).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return "", 0, errors.New("停车记录不存在")
		}
		return "", 0, errors.New("查询停车记录失败")
	}

	amount := record.FeeCalculated
	if amountPtr != nil && *amountPtr > 0 {
		amount = *amountPtr
	}
	// 如果费用未计算且未传入金额，使用默认金额
	if amount <= 0 {
		amount = 10.0 // 默认10元，实际应该根据停车时长计算
	}

	// 创建 pending payment record 直接写入 payment_record 表
	// 注意：由于PaymentRecord的Order字段有外键约束指向ReservationOrder，但这里OrderID是ParkingRecord的ID
	// 所以需要禁用外键检查或使用原生SQL，或者不加载Order关联
	// TransactionNo字段有unique约束，待支付时生成临时唯一值
	now := time.Now()
	p := &model.PaymentRecord{
		OrderID:       record.RecordID, // 在表结构里 OrderID 字段复用为关联 ID（reservation/parking/violation）
		UserID:        record.UserID,
		Amount:        amount,
		Method:        method,
		TransactionNo: fmt.Sprintf("PENDING_%d_%d", record.RecordID, now.Unix()), // 待支付时使用临时唯一值
		PaymentStatus: 0,                                                         // 待支付
		CreateTime:    now,
	}
	// 使用原生SQL插入，临时禁用外键检查，避免外键约束问题
	// 注意：OrderID字段有外键约束指向ReservationOrder，但这里OrderID是ParkingRecord的ID
	// 所以需要临时禁用外键检查
	sqlDB, err := inits.DB.DB()
	if err != nil {
		return "", 0, fmt.Errorf("获取数据库连接失败: %w", err)
	}

	// 临时禁用外键检查
	_, err = sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 0")
	if err != nil {
		return "", 0, fmt.Errorf("禁用外键检查失败: %w", err)
	}
	defer func() {
		sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 1")
	}()

	// 插入支付记录
	result, err := sqlDB.Exec(
		"INSERT INTO payment_record (order_id, user_id, amount, method, transaction_no, payment_status, create_time) VALUES (?, ?, ?, ?, ?, ?, ?)",
		p.OrderID, p.UserID, p.Amount, p.Method, p.TransactionNo, p.PaymentStatus, p.CreateTime,
	)
	if err != nil {
		return "", 0, fmt.Errorf("创建支付记录失败: %w", err)
	}

	// 获取插入的PaymentID
	paymentID, err := result.LastInsertId()
	if err != nil {
		return "", 0, fmt.Errorf("获取支付ID失败: %w", err)
	}
	p.PaymentID = uint64(paymentID)
	u := fmt.Sprintf("%s?provider=%s&payment_id=%d", s.simulateBase, url.QueryEscape(method), p.PaymentID)
	return u, p.PaymentID, nil
}

// ----- violation -----
func (s *Service) createViolationPayment(violationID uint, method string, amountPtr *float64) (string, uint64, error) {
	// 先检查是否已有pending支付记录
	var existingPayment model.PaymentRecord
	if err := inits.DB.Where("order_id = ? AND payment_status = 0", violationID).First(&existingPayment).Error; err == nil {
		// 如果已有pending支付记录，直接返回
		u := fmt.Sprintf("%s?provider=%s&payment_id=%d", s.simulateBase, url.QueryEscape(method), existingPayment.PaymentID)
		return u, existingPayment.PaymentID, nil
	}

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
		TransactionNo: fmt.Sprintf("PENDING_VIO_%d_%d", vio.ViolationID, now.Unix()),
		PaymentStatus: 0,
		CreateTime:    now,
	}

	sqlDB, err := inits.DB.DB()
	if err != nil {
		return "", 0, fmt.Errorf("获取数据库连接失败: %w", err)
	}

	_, err = sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 0")
	if err != nil {
		return "", 0, fmt.Errorf("禁用外键检查失败: %w", err)
	}
	defer func() {
		sqlDB.Exec("SET FOREIGN_KEY_CHECKS = 1")
	}()

	result, err := sqlDB.Exec(
		"INSERT INTO payment_record (order_id, user_id, amount, method, transaction_no, payment_status, create_time) VALUES (?, ?, ?, ?, ?, ?, ?)",
		p.OrderID, p.UserID, p.Amount, p.Method, p.TransactionNo, p.PaymentStatus, p.CreateTime,
	)
	if err != nil {
		return "", 0, fmt.Errorf("创建支付记录失败: %w", err)
	}

	paymentID, err := result.LastInsertId()
	if err != nil {
		return "", 0, fmt.Errorf("获取支付ID失败: %w", err)
	}
	p.PaymentID = uint64(paymentID)

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

	// 保存原始的TransactionNo用于判断支付类型（在更新之前）
	originalTransactionNo := p.TransactionNo

	// 更新 payment_record
	// 检查TransactionNo是否已存在（避免唯一约束冲突）
	if transactionNo != "" {
		var existingPayment model.PaymentRecord
		if err := inits.DB.Where("transaction_no = ? AND payment_id != ?", transactionNo, p.PaymentID).First(&existingPayment).Error; err == nil {
			// 如果已存在相同的交易号且不是当前支付记录，返回错误
			return nil, errors.New("交易号已存在")
		}
	}

	now := time.Now()
	p.PaymentStatus = 1
	p.TransactionNo = transactionNo
	p.Method = provider // ensure provider saved
	p.Amount = amount
	p.PayTime = &now

	if err := inits.DB.Save(&p).Error; err != nil {
		return nil, fmt.Errorf("更新支付记录失败: %w", err)
	}

	// 根据原始TransactionNo前缀判断支付类型（在更新之前保存的）
	// - PENDING_VIO_ 开头：违规支付
	// - PENDING_ 开头：停车支付或预订支付（需要进一步判断）
	
	// 先检查是否是违规支付（通过原始TransactionNo前缀判断）
	// 注意：TransactionNo格式为 "PENDING_VIO_{violation_id}_{timestamp}"，前缀是 "PENDING_VIO_"（12个字符）
	if len(originalTransactionNo) >= 12 && originalTransactionNo[:12] == "PENDING_VIO_" {
		var vio model.ViolationRecord
		if err := inits.DB.First(&vio, p.OrderID).Error; err == nil {
			// 更新违规记录状态为已处理/已支付
			vio.Status = 1
			if err := inits.DB.Save(&vio).Error; err != nil {
				return &p, errors.New("更新违规记录失败")
			}
			return &p, nil
		}
		// 如果找不到违规记录，继续尝试其他类型
	}
	
	// 尝试查找 reservation 表（预订支付）
	var reservation model.ReservationOrder
	if err := inits.DB.First(&reservation, p.OrderID).Error; err == nil {
		// 有 reservation 记录 -> 使用 bookingSvc.PayBooking 以保持一致行为
		_, err := s.bookingSvc.PayBooking(reservation.OrderID, p.UserID, amount, provider, transactionNo)
		if err != nil {
			// 记录已更新为支付，但 bookingSvc 更新失败
			return &p, fmt.Errorf("支付记录已更新，但订单更新失败: %w", err)
		}
		return &p, nil
	}

	// 再尝试 parking_record（停车支付）
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

	// 最后再尝试 violation_record（作为兜底，防止TransactionNo格式异常的情况）
	var vio model.ViolationRecord
	if err := inits.DB.First(&vio, p.OrderID).Error; err == nil {
		// 更新违规记录状态为已处理/已支付
		vio.Status = 1
		if err := inits.DB.Save(&vio).Error; err != nil {
			return &p, errors.New("更新违规记录失败")
		}
		return &p, nil
	}

	// 如果没找到任何关联表，支付记录已经更新为已支付，返回成功
	// 这种情况可能是数据不一致，但支付已经完成，不应该阻止支付流程
	// 记录警告日志，但返回成功
	return &p, nil
}
