package payment

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Handler 支付处理，支持模拟微信/支付宝
type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

// CreatePaymentReq 请求体
type CreatePaymentReq struct {
	OrderID uint     `json:"order_id" binding:"required"` // 对应三类记录的 ID（reservation->OrderID, parking->RecordID, violation->ViolationID）
	Type    string   `json:"type" binding:"required"`     // "reservation" | "parking" | "violation"
	Method  string   `json:"method" binding:"required"`   // "alipay" | "wechat"
	Amount  *float64 `json:"amount,omitempty"`            // 可选：前端可传金额（如停车场/罚单），对于 reservation 若传入覆盖订单金额
	// 备注：如果 amount 不传，则根据后端查出的应付金额自动使用
}

type CreatePaymentResp struct {
	RedirectURL string `json:"redirect_url"`
}

// CreatePaymentRedirectHandler 创建支付（生成模拟支付链接）
func (h *Handler) CreatePaymentRedirectHandler(c *gin.Context) {
	var req CreatePaymentReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误: " + err.Error()})
		return
	}

	url, paymentID, err := h.svc.CreatePayment(req.OrderID, req.Type, req.Method, req.Amount)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"code":       0,
		"message":    "ok",
		"data":       CreatePaymentResp{RedirectURL: url},
		"payment_id": paymentID,
	})
}

// NotifyReq 模拟回调请求体（由模拟支付页面调用）
type NotifyReq struct {
	PaymentID     uint64  `json:"payment_id" binding:"required"`
	Amount        float64 `json:"amount" binding:"required"`
	TransactionNo string  `json:"transaction_no" binding:"required"`
	Provider      string  `json:"provider" binding:"required"` // "alipay" | "wechat"
}

// NotifyHandler 统一接收模拟支付回调并处理（更新 payment_record 与关联订单）
func (h *Handler) NotifyHandler(c *gin.Context) {
	var req NotifyReq
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": "参数错误: " + err.Error()})
		return
	}

	payment, err := h.svc.HandleNotify(req.PaymentID, req.Amount, req.Provider, req.TransactionNo)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"code": 400, "message": err.Error()})
		return
	}

	// 返回 success，模拟支付宝回调习惯
	c.JSON(http.StatusOK, gin.H{"code": 0, "message": "success", "payment_id": payment.PaymentID})
}
