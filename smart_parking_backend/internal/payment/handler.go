package payment

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Handler 支付处理，仅支持支付宝
type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// CreatePaymentReq 请求体：仅包含 order_id
type CreatePaymentReq struct {
	OrderID uint `json:"order_id" binding:"required"`
}

type CreatePaymentResp struct {
	RedirectURL string `json:"redirect_url"`
}

// CreatePaymentRedirectHandler 创建支付宝支付链接
func (h *Handler) CreatePaymentRedirectHandler(c *gin.Context) {
	var req CreatePaymentReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误: " + err.Error()})
		return
	}

	url, err := h.svc.CreatePaymentRedirect(req.OrderID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":    0,
		"message": "ok",
		"data":    CreatePaymentResp{RedirectURL: url},
	})
}

// 支付宝沙箱/模拟回调
type NotifyReq struct {
	OrderID       uint    `json:"order_id" binding:"required"`
	Amount        float64 `json:"amount" binding:"required"`
	TransactionNo string  `json:"transaction_no" binding:"required"`
}

// AlipayNotifyHandler 支付宝支付回调
func (h *Handler) AlipayNotifyHandler(c *gin.Context) {
	var req NotifyReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误: " + err.Error()})
		return
	}

	order, err := h.svc.bookingSvc.GetBookingDetail(req.OrderID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "订单不存在"})
		return
	}

	_, err = h.svc.bookingSvc.PayBooking(req.OrderID, order.UserID, req.Amount, "alipay", req.TransactionNo)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "处理回调失败: " + err.Error()})
		return
	}

	c.String(http.StatusOK, "success")
}
