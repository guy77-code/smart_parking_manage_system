package payment

import (
	"errors"
	"fmt"
	"net/url"
	"smart_parking_backend/internal/inits"
	"smart_parking_backend/internal/model"
	"time"
)

// CreatePaymentURL 创建支付链接
func CreatePaymentURL(orderID uint, amount float64, subject string) (string, error) {
	// 加载支付配置
	cfg, err := LoadSandboxConfig("config/payment.yaml")
	if err != nil {
		return "", errors.New("加载支付配置失败")
	}

	// 构建基础URL
	base := cfg.Alipay.GatewayURL
	if base == "" {
		base = "https://openapi.alipaydev.com/gateway.do"
	}

	// 构建参数
	params := url.Values{}
	params.Add("app_id", cfg.Alipay.AppID)
	params.Add("method", "alipay.trade.page.pay")
	params.Add("charset", cfg.Alipay.Charset)
	params.Add("sign_type", cfg.Alipay.SignType)
	params.Add("notify_url", cfg.Alipay.NotifyURL)
	params.Add("return_url", cfg.Alipay.ReturnURL)

	// 构建业务内容
	bizContent := fmt.Sprintf(
		`{"out_trade_no":"%d","product_code":"FAST_INSTANT_TRADE_PAY","total_amount":"%.2f","subject":"%s-%d"}`,
		orderID, amount, subject, orderID,
	)
	params.Add("biz_content", bizContent)

	// 构建完整URL
	redirectURL := base + "?" + params.Encode()

	// 根据订单类型创建支付记录
	switch subject {
	case "停车费":
		// 查找停车记录
		var record model.ParkingRecord
		if err := inits.DB.First(&record, orderID).Error; err != nil {
			return "", errors.New("停车记录不存在")
		}

		// 创建支付记录
		_, err = createPendingPayment(record.UserID, orderID, amount)

	case "违规罚款":
		// 查找违规记录
		var violation model.ViolationRecord
		if err := inits.DB.First(&violation, orderID).Error; err != nil {
			return "", errors.New("违规记录不存在")
		}

		// 创建支付记录
		_, err = createPendingPayment(violation.UserID, orderID, amount)

	default:
		return "", errors.New("未知的支付类型: " + subject)
	}

	if err != nil {
		return "", err
	}

	return redirectURL, nil
}

// createPendingPayment 创建待支付记录
func createPendingPayment(userID, orderID uint, amount float64) (*model.PaymentRecord, error) {
	payment := model.PaymentRecord{
		UserID:        userID,
		OrderID:       orderID,
		Amount:        amount,
		Method:        "alipay",
		PaymentStatus: 0, // 0-待支付
		CreateTime:    time.Now(),
	}

	if err := inits.DB.Create(&payment).Error; err != nil {
		return nil, err
	}

	return &payment, nil
}
