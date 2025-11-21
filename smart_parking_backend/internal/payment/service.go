package payment

import (
	"errors"
	"fmt"
	"net/url"

	"smart_parking_backend/internal/booking"
)

type Service struct {
	bookingSvc *booking.Service
	cfg        *Config
}

func NewService(bookingSvc *booking.Service, cfg *Config) *Service {
	return &Service{
		bookingSvc: bookingSvc,
		cfg:        cfg,
	}
}

func (s *Service) Config() *Config {
	return s.cfg
}

// CreatePaymentRedirect 根据订单生成支付宝沙箱跳转 URL
func (s *Service) CreatePaymentRedirect(orderID uint) (string, error) {
	order, err := s.bookingSvc.GetBookingDetail(orderID)
	if err != nil {
		return "", errors.New("订单不存在")
	}

	if order.PaymentStatus == 1 {
		return "", errors.New("订单已支付")
	}
	if order.Status == 0 {
		return "", errors.New("订单已取消")
	}

	amount := order.TotalFee
	if amount <= 0 {
		return "", errors.New("订单金额为0，请先确认订单应付金额")
	}

	base := s.cfg.Alipay.GatewayURL
	if base == "" {
		base = "https://openapi.alipaydev.com/gateway.do"
	}

	params := url.Values{}
	params.Add("app_id", s.cfg.Alipay.AppID)
	params.Add("method", "alipay.trade.page.pay")
	params.Add("charset", s.cfg.Alipay.Charset)
	params.Add("sign_type", s.cfg.Alipay.SignType)
	params.Add("notify_url", s.cfg.Alipay.NotifyURL)
	params.Add("return_url", s.cfg.Alipay.ReturnURL)

	bizContent := fmt.Sprintf(
		`{"out_trade_no":"%d","product_code":"FAST_INSTANT_TRADE_PAY","total_amount":"%.2f","subject":"停车预订订单-%d"}`,
		order.OrderID, amount, order.OrderID,
	)
	params.Add("biz_content", bizContent)

	redirectURL := base + "?" + params.Encode()

	_, err = s.bookingSvc.CreatePendingPayment(order.OrderID, order.UserID, amount, "alipay", "")
	if err != nil {
		return "", err
	}

	return redirectURL, nil
}
