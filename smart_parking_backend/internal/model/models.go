package model

import (
	"time"
)

// ////////////////////
// 用户信息表
// ////////////////////
type Users_list struct {
	UserID       uint       `gorm:"primaryKey;autoIncrement;comment:用户唯一标识" json:"user_id"`
	Username     string     `gorm:"size:50;unique;not null;comment:用户名（登录名）" json:"username"`
	PasswordHash string     `gorm:"size:255;not null;comment:密码哈希值" json:"password_hash"`
	Phone        string     `gorm:"size:20;not null;index:idx_phone;comment:手机号" json:"phone"`
	Email        string     `gorm:"size:100;index:idx_email;comment:邮箱" json:"email"`
	RealName     string     `gorm:"size:50;comment:真实姓名" json:"real_name"`
	RegisterTime time.Time  `gorm:"autoCreateTime;comment:注册时间" json:"register_time"`
	LastLogin    *time.Time `gorm:"comment:最后登录时间" json:"last_login"`
	Status       int8       `gorm:"default:1;comment:账户状态（0-禁用，1-正常）" json:"status"`

	// 关联关系
	Vehicles     []Vehicle          `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
	Reservations []ReservationOrder `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
	Payments     []PaymentRecord    `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
	ParkRecords  []ParkingRecord    `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
	Violations   []ViolationRecord  `gorm:"foreignKey:UserID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
}

func (Users_list) TableName() string { return "users_list" }

// ////////////////////
// 管理员信息表
// ////////////////////
type Admins struct {
	AdminID      uint        `gorm:"primaryKey;autoIncrement;comment:管理员ID" json:"admin_id"`
	Username     string      `gorm:"size:50;unique;not null;comment:登录名" json:"username"`
	PasswordHash string      `gorm:"size:255;not null;comment:加密密码" json:"password_hash"`
	PhoneNumber  string      `gorm:"size:20;uniqueIndex;comment:电话号码" json:"phone_number"`
	Role         string      `gorm:"type:enum('system','lot_admin');default:'lot_admin';comment:角色类型" json:"role"`
	LotID        *uint       `gorm:"comment:若是停车场管理员，对应停车场ID" json:"lot_id"`
	Lot          *ParkingLot `gorm:"constraint:OnUpdate:CASCADE,OnDelete:SET NULL" json:"lot,omitempty"`
	Status       int8        `gorm:"default:1;comment:状态（0-禁用，1-启用）" json:"status"`
	CreateTime   time.Time   `gorm:"autoCreateTime;comment:创建时间" json:"create_time"`
}

func (Admins) TableName() string { return "admins_list" }

// ////////////////////
// 用户车辆表
// ////////////////////
type Vehicle struct {
	VehicleID    uint       `gorm:"primaryKey;autoIncrement;comment:车辆唯一标识" json:"vehicle_id"`
	UserID       uint       `gorm:"not null;index:idx_user_id;comment:关联用户ID" json:"user_id"`
	User         Users_list `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID;references:UserID" json:"user"`
	LicensePlate string     `gorm:"size:20;unique;not null;comment:车牌号" json:"LicensePlate"`
	Brand        string     `gorm:"size:50;comment:车辆品牌" json:"Brand"`
	Model        string     `gorm:"size:50;comment:车型" json:"Model"`
	Color        string     `gorm:"size:20;comment:车辆颜色" json:"Color"`
	AddTime      time.Time  `gorm:"autoCreateTime;comment:添加时间" json:"AddTime"`

	Reservations []ReservationOrder `gorm:"foreignKey:VehicleID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	ParkRecords  []ParkingRecord    `gorm:"foreignKey:VehicleID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
	Violations   []ViolationRecord  `gorm:"foreignKey:VehicleID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" `
}

func (Vehicle) TableName() string { return "vehicle" }

// ////////////////////
// 停车场基本信息表
// ////////////////////
type ParkingLot struct {
	LotID       uint      `gorm:"primaryKey;autoIncrement;comment:停车场唯一标识" json:"lot_id"`
	Name        string    `gorm:"size:100;not null;comment:停车场名称" json:"name"`
	Address     string    `gorm:"size:255;not null;comment:详细地址" json:"address"`
	TotalLevels int       `gorm:"default:1;comment:总层数" json:"total_levels"`
	TotalSpaces int       `gorm:"default:0;comment:总车位数" json:"total_spaces"`
	HourlyRate  float64   `gorm:"type:decimal(8,2);default:5.00;comment:小时费率" json:"hourly_rate"`
	Status      int8      `gorm:"default:1;comment:状态（0-关闭，1-开放）" json:"status"`
	Description string    `gorm:"type:text;comment:描述信息" json:"description"`
	CreateTime  time.Time `gorm:"autoCreateTime;comment:创建时间" json:"create_time"`
	UpdateTime  time.Time `gorm:"autoUpdateTime;comment:更新时间" json:"update_time"`

	Spaces         []ParkingSpace     `gorm:"foreignKey:LotID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	Reservations   []ReservationOrder `gorm:"foreignKey:LotID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
	ParkingRecords []ParkingRecord    `gorm:"foreignKey:LotID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

func (ParkingLot) TableName() string { return "parking_lot" }

// ////////////////////
// 车位信息表
// ////////////////////
type ParkingSpace struct {
	SpaceID      uint               `gorm:"primaryKey;autoIncrement;comment:车位唯一标识" json:"space_id"`
	LotID        uint               `gorm:"not null;index:idx_lot_id;comment:所属停车场ID" json:"lot_id"`
	Lot          ParkingLot         `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:LotID;references:LotID" json:"lot"`
	Level        int                `gorm:"default:1;not null;comment:所在楼层" json:"level"`
	SpaceNumber  string             `gorm:"size:20;not null;comment:车位编号" json:"space_number"`
	SpaceType    string             `gorm:"size:20;default:'普通';comment:车位类型" json:"space_type"`
	IsOccupied   int8               `gorm:"default:0;comment:是否被占用" json:"is_occupied"`
	IsReserved   int8               `gorm:"default:0;comment:是否已被预订" json:"is_reserved"`
	Status       int8               `gorm:"default:1;comment:状态（0-禁用，1-可用）" json:"status"`
	LastUpdate   time.Time          `gorm:"autoUpdateTime;comment:最后状态更新时间" json:"last_update"`
	Reservations []ReservationOrder `gorm:"foreignKey:SpaceID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" json:"reservations"`
	ParkRecords  []ParkingRecord    `gorm:"foreignKey:SpaceID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE" json:"park_records"`
}

func (ParkingSpace) TableName() string { return "parking_space" }

// ////////////////////
// 预订订单表
// ////////////////////
type ReservationOrder struct {
	OrderID         uint         `gorm:"primaryKey;autoIncrement;comment:订单唯一标识" json:"order_id"`
	UserID          uint         `gorm:"index:idx_user_id;not null;comment:预订用户ID" json:"user_id"`
	User            Users_list   `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID;references:UserID" json:"user"`
	VehicleID       uint         `gorm:"not null;comment:预订车辆ID" json:"vehicle_id"`
	Vehicle         Vehicle      `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:VehicleID;references:VehicleID" json:"vehicle"`
	SpaceID         uint         `gorm:"index:idx_space_id;not null;comment:预订车位ID" json:"space_id"`
	Space           ParkingSpace `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:SpaceID;references:SpaceID" json:"space"`
	LotID           uint         `gorm:"not null;comment:所属停车场ID" json:"lot_id"`
	Lot             ParkingLot   `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:LotID;references:LotID" json:"lot"`
	StartTime       time.Time    `gorm:"not null;comment:预订开始时间" json:"start_time"`
	EndTime         time.Time    `gorm:"not null;comment:预订结束时间" json:"end_time"`
	ActualEndTime   *time.Time   `gorm:"comment:实际离场时间" json:"actual_end_time"`
	DurationMinutes int          `gorm:"comment:预订时长（分钟）" json:"duration_minut"`
	BookingTime     time.Time    `gorm:"autoCreateTime;comment:预订下单时间" json:"booking_time"`
	Status          int8         `gorm:"default:1;comment:订单状态（0-已取消，1-已预订，2-使用中，3-已完成）" json:"status"`
	TotalFee        float64      `gorm:"type:decimal(10,2);default:0.00;comment:应付总费用" json:"total_fee"`
	PaidFee         float64      `gorm:"type:decimal(10,2);default:0.00;comment:实付金额" json:"paid_fee"`
	PaymentStatus   int8         `gorm:"default:0;comment:支付状态（0-未支付，1-已支付）" json:"payment_status"`
	ReservationCode string       `gorm:"size:50;unique;not null;index:idx_reservation_code;comment:预订编号" json:"reservation_cod"`

	Payments []PaymentRecord `gorm:"foreignKey:OrderID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

func (ReservationOrder) TableName() string { return "reservation_order" }

// ////////////////////
// 支付记录表
// ////////////////////
type PaymentRecord struct {
	PaymentID     uint64           `gorm:"primaryKey;autoIncrement;comment:支付流水号" json:"payment_id"`
	OrderID       uint             `gorm:"index:idx_order_id;not null;comment:关联的订单ID" json:"order_id"`
	Order         ReservationOrder `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:OrderID;references:OrderID" json:"order"`
	UserID        uint             `gorm:"index:idx_user_id;not null;comment:用户ID" json:"user_id"`
	User          Users_list       `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID;references:UserID" json:"user"`
	Amount        float64          `gorm:"type:decimal(10,2);not null;comment:支付金额" json:"amount"`
	Method        string           `gorm:"type:enum('wechat','alipay','credit_card','wallet');not null;comment:支付方式" json:"method"`
	TransactionNo string           `gorm:"size:100;unique;comment:第三方支付平台交易号" json:"transaction_no"`
	PaymentStatus int8             `gorm:"default:0;comment:支付状态（0-待支付，1-支付成功，2-失败，3-退款）" json:"payment_status"`
	PayTime       *time.Time       `gorm:"comment:支付时间" json:"pay_time"`
	RefundTime    *time.Time       `gorm:"comment:退款时间" json:"refund_time"`
	CreateTime    time.Time        `gorm:"autoCreateTime;comment:创建时间" json:"create_time"`
}

func (PaymentRecord) TableName() string { return "payment_record" }

// ////////////////////
// 停车记录表
// ////////////////////
type ParkingRecord struct {
	RecordID        uint         `gorm:"primaryKey;autoIncrement;comment:停车记录唯一标识" json:"record_id"`
	UserID          uint         `gorm:"index:idx_user_id;not null;comment:用户ID" json:"user_id"`
	User            Users_list   `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID;references:UserID" json:"user"`
	VehicleID       uint         `gorm:"index:idx_vehicle_id;not null;comment:车辆ID" json:"vehicle_id"`
	Vehicle         Vehicle      `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:VehicleID;references:VehicleID" json:"vehicle"`
	SpaceID         uint         `gorm:"not null;comment:车位ID" json:"space_id"`
	Space           ParkingSpace `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:SpaceID;references:SpaceID" json:"space"`
	LotID           uint         `gorm:"not null;comment:停车场ID" json:"lot_id"`
	Lot             ParkingLot   `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:LotID;references:LotID" json:"lot"`
	EntryTime       time.Time    `gorm:"not null;comment:入场时间" json:"entry_time"`
	ExitTime        *time.Time   `gorm:"comment:出场时间" json:"exit_time"`
	DurationMinutes int          `gorm:"comment:停车时长（分钟）" json:"duration_minute"`
	FeeCalculated   float64      `gorm:"type:decimal(10,2);default:0.00;comment:计算停车费" json:"fee_calculated"`
	FeePaid         float64      `gorm:"type:decimal(10,2);default:0.00;comment:实际支付停车费" json:"fee_paid"`
	PaymentStatus   int8         `gorm:"default:0;comment:支付状态（0-未支付，1-已支付）" json:"payment_status"`
	IsViolation     int8         `gorm:"default:0;index:idx_violation;comment:是否违规" json:"is_violation"`
	ViolationReason string       `gorm:"size:255;comment:违规原因" json:"violation_reason"`
	RecordStatus    int8         `gorm:"default:1;index:idx_record_status;comment:记录状态（1-在场，2-已出场）" json:"record_status"`
	CreateTime      time.Time    `gorm:"autoCreateTime;comment:记录创建时间" json:"create_time"`

	Violations []ViolationRecord `gorm:"foreignKey:RecordID;constraint:OnUpdate:CASCADE,OnDelete:CASCADE"`
}

func (ParkingRecord) TableName() string { return "parking_record" }

// ////////////////////
// 违规记录表
// ////////////////////
type ViolationRecord struct {
	ViolationID   uint          `gorm:"primaryKey;autoIncrement;comment:违规记录唯一标识" json:"violation_id"`
	RecordID      uint          `gorm:"index:idx_record_id;not null;comment:关联停车记录ID" json:"record_id"`
	Record        ParkingRecord `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:RecordID;references:RecordID" json:"record"`
	UserID        uint          `gorm:"index:idx_user_id;not null;comment:用户ID" json:"user_id"`
	User          Users_list    `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:UserID;references:UserID" json:"user"`
	VehicleID     uint          `gorm:"not null;comment:车辆ID" json:"vehicle_id"`
	Vehicle       Vehicle       `gorm:"constraint:OnUpdate:CASCADE,OnDelete:CASCADE;foreignKey:VehicleID;references:VehicleID" json:"vehicle"`
	ViolationType string        `gorm:"size:50;not null;comment:违规类型" json:"violation_type"`
	ViolationTime time.Time     `gorm:"not null;index:idx_violation_time;comment:违规发生时间" json:"violation_time"`
	Description   string        `gorm:"type:text;comment:违规描述" json:"description"`
	FineAmount    float64       `gorm:"type:decimal(10,2);default:0.00;comment:罚款金额" json:"fine_amount"`
	Status        int8          `gorm:"default:0;index:idx_status;comment:处理状态（0-未处理，1-已处理）" json:"status"`
	CreateTime    time.Time     `gorm:"autoCreateTime;comment:记录创建时间" json:"create_time"`
	ProcessTime   *time.Time    `gorm:"comment:处理时间" json:"process_time"`
}

func (ViolationRecord) TableName() string { return "violation_record" }
