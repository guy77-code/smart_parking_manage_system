import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    // 避免支付成功逻辑被重复触发（paymentNotified 与 requestFinished 都会回调）
    property bool paymentHandled: false
    id: paymentPage
    title: "支付"

    signal paymentSucceeded(string orderType, int orderId)

    property int orderId: 0
    property string orderType: "parking"  // "reservation", "parking", "violation"
    property double amount: 0.0
    property int paymentId: 0
    property string paymentMethod: "alipay"
    property var orderTypeSequence: []
    property int orderTypeIndex: -1
    property var triedOrderTypes: []

    Component.onCompleted: {
        setupOrderTypeSequence()
        // 如果已经有paymentId，直接模拟支付
        if (paymentId > 0 && amount > 0) {
            statusText.text = "正在处理支付..."
            statusText.color = "blue"
            var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
            apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.5, 400)
        spacing: 20

        Text {
            Layout.fillWidth: true
            text: "支付订单"
            font.pixelSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            Layout.fillWidth: true
            text: "订单ID: " + orderId
            font.pixelSize: 16
        }

        Text {
            Layout.fillWidth: true
            text: "支付金额: ¥" + amount.toFixed(2)
            font.pixelSize: 18
            font.bold: true
        }

        Text {
            Layout.fillWidth: true
            text: "支付方式:"
            font.pixelSize: 14
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "支付宝"
                Layout.fillWidth: true
                checked: paymentMethod === "alipay"
                checkable: true
                onClicked: paymentMethod = "alipay"
            }
            Button {
                text: "微信"
                Layout.fillWidth: true
                checked: paymentMethod === "wechat"
                checkable: true
                onClicked: paymentMethod = "wechat"
            }
        }

        Button {
            Layout.fillWidth: true
            text: paymentId > 0 ? "确认支付" : "创建支付"
            enabled: orderId > 0 && amount > 0
            onClicked: {
                if (paymentId > 0) {
                    processPaymentNotification()
                } else {
                    createPaymentRequest()
                }
            }
        }

        Button {
            Layout.fillWidth: true
            text: "取消"
            onClicked: {
                safeGoBack()
            }
        }

        Text {
            id: statusText
            Layout.fillWidth: true
            color: "red"
            wrapMode: Text.Wrap
            visible: text.length > 0
        }
    }

    // 安全的返回逻辑，防止 pop 导致堆栈为空从而重置到 Login
    function safeGoBack() {
        if (!stackView) {
            console.log("Cannot go back: stackView is null")
            return
        }
        
        // 确保堆栈深度大于1才执行pop，避免清空堆栈导致回到登录页
        var depth = stackView.depth || 0
        console.log("Stack depth:", depth)
        
        if (depth > 1) {
            console.log("Popping payment page, remaining depth:", depth - 1)
            stackView.pop()
        } else {
            // 如果这是唯一的页面，不应该pop，避免回到登录页
            console.log("Cannot pop: Stack depth is 1 or less, preventing navigation to login")
            // 不执行任何操作，保持在当前页面
        }
    }

    function setupOrderTypeSequence() {
        triedOrderTypes = []
        // 修改点：如果是违规类型，强制锁定，禁止重试其他类型
        if (orderType === "violation") {
            orderTypeSequence = ["violation"]
            orderTypeIndex = 0
            return
        }

        if (!orderTypeSequence || orderTypeSequence.length === 0) {
            var defaults = []
            if (orderType && orderType.length > 0) {
                defaults.push(orderType)
            }
            var fallbacks = ["reservation", "parking"] // 移除了 violation 作为 fallback，避免逻辑混乱
            for (var i = 0; i < fallbacks.length; i++) {
                if (defaults.indexOf(fallbacks[i]) < 0) {
                    defaults.push(fallbacks[i])
                }
            }
            orderTypeSequence = defaults
        }
        if (!orderType || orderType.length === 0) {
            orderType = orderTypeSequence[0]
        }
        orderTypeIndex = Math.max(0, orderTypeSequence.indexOf(orderType))
        orderType = orderTypeSequence[orderTypeIndex]
    }

    function processPaymentNotification() {
        if (paymentId <= 0 || amount <= 0) {
            statusText.text = "无效的支付信息"
            statusText.color = "red"
            return
        }
        statusText.text = "正在处理支付..."
        statusText.color = "blue"
        var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
        apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
    }

    function createPaymentRequest() {
        if (orderId <= 0 || amount <= 0) {
            statusText.text = "订单信息不完整"
            statusText.color = "red"
            return
        }
        triedOrderTypes.push(orderType)
        console.log("Creating payment - OrderID:", orderId, "Type:", orderType, "Method:", paymentMethod, "Amount:", amount)
        statusText.text = "正在创建支付..."
        statusText.color = "blue"
        
        // 如果是违规类型，且 apiClient 有特定的 payViolation 方法，建议使用专门的方法
        // 这里假设依然使用通用的 createPayment，但后端逻辑已修正
        apiClient.createPayment(orderId, orderType, paymentMethod, amount)
    }

    function shouldRetryWithNextType(message) {
        if (!message) return false
        
        // 修改点：如果是违规订单失败，绝不重试其他类型
        if (orderType === "violation") return false

        var indicators = ["不存在", "未知的订单类型", "not exist", "not found"]
        for (var i = 0; i < indicators.length; i++) {
            if (message.toLowerCase().indexOf(indicators[i]) >= 0)
                return true
        }
        return false
    }

    function tryNextOrderType() {
        if (!orderTypeSequence || orderTypeSequence.length === 0)
            return ""
        for (var i = orderTypeIndex + 1; i < orderTypeSequence.length; i++) {
            if (triedOrderTypes.indexOf(orderTypeSequence[i]) < 0) {
                orderTypeIndex = i
                orderType = orderTypeSequence[i]
                return orderType
            }
        }
        return ""
    }

    function handlePaymentCreationError(message) {
        var readableMessage = message || "创建支付失败"
        if (shouldRetryWithNextType(readableMessage)) {
            var nextType = tryNextOrderType()
            if (nextType && nextType.length > 0) {
                statusText.text = "尝试以“" + orderTypeLabel(nextType) + "”重新创建支付..."
                statusText.color = "orange"
                createPaymentRequest()
                return
            }
        }
        statusText.text = readableMessage
        statusText.color = "red"
        // 移除导致自动退回登录的逻辑（如果有的话），保持停留在当前页面显示错误
    }

    function orderTypeLabel(type) {
        if (type === "reservation") return "预约订单"
        if (type === "parking") return "停车订单"
        if (type === "violation") return "违规订单"
        return type
    }

    Connections {
        target: apiClient

        function onPaymentCreated(payment) {
            // ... (保持原有逻辑) ...
            paymentId = payment.payment_id || payment.paymentId || 0
            var redirectUrl = ""
            if (payment.data && payment.data.redirect_url) {
                redirectUrl = payment.data.redirect_url
            } else if (payment.redirect_url) {
                redirectUrl = payment.redirect_url
            }
            
            if (redirectUrl.length > 0) {
                var urlParts = redirectUrl.split("payment_id=")
                if (urlParts.length > 1) {
                    paymentId = parseInt(urlParts[1]) || paymentId
                }
                processPaymentNotification()
            } else if (paymentId > 0) {
                processPaymentNotification()
            } else {
                statusText.text = "创建支付失败：未获取到支付ID"
                statusText.color = "red"
            }
        }

        function onPaymentNotified(response) {
            // 支付通知接口：即使返回错误，如果支付记录已更新，也应该视为成功
            if (paymentHandled) {
                console.log("Payment already handled, skip onPaymentNotified")
                return
            }
            var isSuccess = false
            var errorMsg = response.message || response.error || ""
            
            if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                isSuccess = true
            } else if (errorMsg.indexOf("支付已记录") >= 0 || errorMsg.indexOf("支付记录已更新") >= 0) {
                // 支付记录已更新，视为成功
                isSuccess = true
            }
            
            if (isSuccess) {
                statusText.text = "支付成功！"
                statusText.color = "green"
                paymentHandled = true
                // 触发支付成功信号，让父页面刷新数据
                paymentSucceeded(orderType, orderId)
                // 延迟返回，确保信号已发送，并且给足够的时间让回调处理完成
                Qt.callLater(function() {
                    // 再次检查堆栈深度，确保安全返回
                    if (stackView && stackView.depth > 1) {
                        console.log("Safely going back after payment success")
                        safeGoBack() // 使用安全的返回函数
                    } else {
                        console.log("Cannot go back: stack depth is", stackView ? stackView.depth : "null")
                    }
                })
            } else {
                statusText.text = errorMsg || "支付失败"
                statusText.color = "red"
                // 支付失败时不返回，让用户看到错误信息
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                var errorMsg = response.error || response.message || "未知错误"
                var errUrl = response.url || ""
                console.log("Payment error:", errorMsg)
                
                // 只有在创建支付接口出错时才尝试重试逻辑
                if (errUrl.indexOf("/payment/create") >= 0 || errUrl.indexOf("/pay") >= 0) {
                    handlePaymentCreationError(errorMsg)
                } else {
                    statusText.text = errorMsg
                    statusText.color = "red"
                }
                return
            }

            var url = response.url || ""
            
            // 兼容通用的创建接口和专门的违规支付接口
            if (url.indexOf("/payment/create") >= 0 || (url.indexOf("/violations/") >= 0 && url.indexOf("/pay") >= 0)) {
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error") && (response.payment_id || response.paymentId))) {
                    
                    paymentId = response.payment_id || response.paymentId || 0
                    var redirectUrl = response.payment_url || response.redirect_url || ""
                    if (response.data && response.data.redirect_url) {
                        redirectUrl = response.data.redirect_url
                    }

                    if (redirectUrl.length > 0) {
                        var urlParts = redirectUrl.split("payment_id=")
                        if (urlParts.length > 1) {
                            var extractedId = parseInt(urlParts[1].split("&")[0])
                            if (extractedId > 0) {
                                paymentId = extractedId
                            }
                        }
                    }
                    
                    if (paymentId > 0) {
                        statusText.text = "支付创建成功，正在处理支付..."
                        statusText.color = "blue"
                        processPaymentNotification()
                    } else {
                        statusText.text = "创建支付失败：未获取到支付ID"
                        statusText.color = "red"
                    }
                } else {
                    var failureMsg = response.message || "创建支付失败"
                    handlePaymentCreationError(failureMsg)
                }
            } else if (url.indexOf("/payment/notify") >= 0) {
                // 与 onPaymentNotified 重复的回调，这里只负责兜底刷新和日志，避免重复返回
                if (paymentHandled) {
                    console.log("Payment notify already handled, skip duplicate handling")
                    return
                }
                var isSuccess = false
                var errorMsg = response.message || response.error || ""
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                    isSuccess = true
                } else if (errorMsg.indexOf("支付已记录") >= 0 || errorMsg.indexOf("支付记录已更新") >= 0) {
                    isSuccess = true
                }
                if (isSuccess) {
                    paymentHandled = true
                    statusText.text = "支付成功！"
                    statusText.color = "green"
                    paymentSucceeded(orderType, orderId)
                    Qt.callLater(function() {
                        if (stackView && stackView.depth > 1) {
                            console.log("Safely going back after payment success (requestFinished)")
                            safeGoBack()
                        } else {
                            console.log("Cannot go back: stack depth is", stackView ? stackView.depth : "null")
                        }
                    })
                } else {
                    statusText.text = errorMsg || "支付失败"
                    statusText.color = "red"
                }
            }
        }
    }
}