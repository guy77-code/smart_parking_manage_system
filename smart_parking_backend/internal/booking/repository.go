package booking

import (
	"errors"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"

	"gorm.io/gorm"
)

// Repository 数据访问层结构体，封装所有数据库操作
type Repository struct{}

// NewRepository 创建 Repository 实例
func NewRepository() *Repository {
	return &Repository{}
}

// ==================== 预订（ReservationOrder）操作 ====================

func (r *Repository) CreateBooking(order *model.ReservationOrder) error {
	return inits.DB.Create(order).Error
}

func (r *Repository) GetBookingByID(orderID uint) (*model.ReservationOrder, error) {
	var order model.ReservationOrder
	err := inits.DB.Preload("User").Preload("Vehicle").Preload("Space").Preload("Lot").
		First(&order, orderID).Error
	return &order, err
}

func (r *Repository) UpdateBooking(order *model.ReservationOrder) error {
	return inits.DB.Save(order).Error
}

func (r *Repository) FindBookingsByUser(userID uint) ([]model.ReservationOrder, error) {
	var list []model.ReservationOrder
	err := inits.DB.Where("user_id = ?", userID).
		Preload("Vehicle").Preload("Space").Preload("Lot").
		Find(&list).Error
	return list, err
}

// ==================== 支付记录（PaymentRecord）操作 ====================

func (r *Repository) CreatePayment(p *model.PaymentRecord) error {
	return inits.DB.Create(p).Error
}

func (r *Repository) GetPaymentByID(paymentID uint64) (*model.PaymentRecord, error) {
	var pay model.PaymentRecord
	err := inits.DB.Preload("User").Preload("Order").
		First(&pay, paymentID).Error
	return &pay, err
}

func (r *Repository) FindPaymentsByUser(userID uint) ([]model.PaymentRecord, error) {
	var list []model.PaymentRecord
	err := inits.DB.Where("user_id = ?", userID).
		Preload("Order").
		Find(&list).Error
	return list, err
}

// 根据 OrderID 查找状态为待支付的支付记录
func (r *Repository) FindPendingPaymentByOrder(orderID uint) (*model.PaymentRecord, error) {
	var p model.PaymentRecord
	err := inits.DB.Where("order_id = ? AND payment_status = 0", orderID).First(&p).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, nil // 没有 pending 记录，返回 nil 而不是 error
	}
	return &p, err
}

// 更新支付记录
func (r *Repository) UpdatePayment(p *model.PaymentRecord) error {
	return inits.DB.Save(p).Error
}

// ==================== 车位（ParkingSpace）操作 ====================

func (r *Repository) FindAvailableSlot(lotID uint, spaceType string) (*model.ParkingSpace, error) {
	var space model.ParkingSpace
	query := inits.DB.Where("lot_id = ? AND is_reserved = 0 AND is_occupied = 0 AND status = 1", lotID)
	
	// 如果指定了车位类型，优先查找该类型的车位
	if spaceType != "" && spaceType != "普通" {
		query = query.Where("space_type = ?", spaceType)
	}
	
	err := query.First(&space).Error
	if errors.Is(err, gorm.ErrRecordNotFound) {
		// 如果指定了类型但找不到，尝试查找普通车位
		if spaceType != "" && spaceType != "普通" {
			var normalSpace model.ParkingSpace
			err2 := inits.DB.Where("lot_id = ? AND is_reserved = 0 AND is_occupied = 0 AND status = 1 AND space_type = ?", lotID, "普通").
				First(&normalSpace).Error
			if err2 == nil {
				return &normalSpace, nil
			}
		}
		return nil, errors.New("no available parking space")
	}
	return &space, err
}

func (r *Repository) MarkSlotAsBooked(spaceID uint, booked bool) error {
	status := int8(0)
	if booked {
		status = 1
	}
	return inits.DB.Model(&model.ParkingSpace{}).
		Where("space_id = ?", spaceID).
		Update("is_reserved", status).Error
}

// ==================== 车辆（Vehicle）操作 ====================

func (r *Repository) FindUserVehicles(userID uint) ([]model.Vehicle, error) {
	var list []model.Vehicle
	err := inits.DB.Where("user_id = ?", userID).Find(&list).Error
	return list, err
}

func (r *Repository) GetVehicleByID(vehicleID uint) (*model.Vehicle, error) {
	var v model.Vehicle
	err := inits.DB.First(&v, vehicleID).Error
	return &v, err
}

// ==================== 事务性操作（预订+支付） ====================

func (r *Repository) CreateBookingWithPayment(order *model.ReservationOrder, payment *model.PaymentRecord) error {
	return inits.DB.Transaction(func(tx *gorm.DB) error {
		if err := tx.Create(order).Error; err != nil {
			return err
		}
		payment.OrderID = order.OrderID
		if err := tx.Create(payment).Error; err != nil {
			return err
		}
		if err := tx.Model(&model.ParkingSpace{}).
			Where("space_id = ?", order.SpaceID).
			Update("is_reserved", 1).Error; err != nil {
			return err
		}
		return nil
	})
}

// ==================== 车位状态更新（占用/释放） ====================

func (r *Repository) FindAvailableSpace(lotID uint) (*model.ParkingSpace, error) {
	var space model.ParkingSpace
	err := inits.DB.Where("lot_id = ? AND is_occupied = 0", lotID).First(&space).Error
	return &space, err
}

func (r *Repository) MarkSpaceAsOccupied(spaceID uint, occupied bool) error {
	return inits.DB.Model(&model.ParkingSpace{}).
		Where("space_id = ?", spaceID).
		Update("is_occupied", occupied).Error
}
