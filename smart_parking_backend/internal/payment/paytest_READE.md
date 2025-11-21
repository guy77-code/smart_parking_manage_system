# Payment (沙箱) 测试说明

1. 生成支付跳转（前端）
   POST /api/payment/create
   Body: { "order_id": 123, "method": "alipay" }

   Response: { data: { "redirect_url": "https://openapi.alipaydev.com/gateway.do?..." } }

   前端可用 Qt 打开该 URL（内置 WebView 或系统浏览器）来模拟跳转支付宝沙箱页面。

2. 模拟回调（测试）
   POST /api/payment/notify/alipay
   Body: { "order_id": 123, "amount": 20.00, "transaction_no": "TXN123456", "method": "alipay" }

   服务端将调用 booking.Service.PayBooking 完成订单状态更新。

3. 查询订单状态
   使用 booking 的 GetBookingDetail 接口查看订单 PaymentStatus、PaidFee 是否更新为已支付。
