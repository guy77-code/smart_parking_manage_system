import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    id: paymentPage
    title: "支付"

    property int orderId: 0
    property string orderType: "parking"  // "reservation", "parking", "violation"
    property double amount: 0.0
    property int paymentId: 0
    property string paymentMethod: "alipay"
    
    Component.onCompleted: {
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

        // Payment method selection
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

        // Payment button
        Button {
            Layout.fillWidth: true
            text: paymentId > 0 ? "确认支付" : "创建支付"
            enabled: orderId > 0 && amount > 0
            onClicked: {
                if (paymentId > 0) {
                    // 直接模拟支付
                    statusText.text = "正在处理支付..."
                    statusText.color = "blue"
                    var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
                    apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
                } else {
                    // Create payment first
                    console.log("Creating payment - OrderID:", orderId, "Type:", orderType, "Method:", paymentMethod, "Amount:", amount)
                    statusText.text = "正在创建支付..."
                    statusText.color = "blue"
                    apiClient.createPayment(orderId, orderType, paymentMethod, amount)
                }
            }
        }

        Button {
            Layout.fillWidth: true
            text: "取消"
            onClicked: {
                stackView.pop()
            }
        }

        // Status message
        Text {
            id: statusText
            Layout.fillWidth: true
            color: "red"
            wrapMode: Text.Wrap
            visible: text.length > 0
        }
    }

    Connections {
        target: apiClient

        function onPaymentCreated(payment) {
            paymentId = payment.payment_id || payment.paymentId || 0
            var redirectUrl = ""
            if (payment.data && payment.data.redirect_url) {
                redirectUrl = payment.data.redirect_url
            } else if (payment.redirect_url) {
                redirectUrl = payment.redirect_url
            }
            
            if (redirectUrl.length > 0) {
                // Extract payment_id from URL if needed
                var urlParts = redirectUrl.split("payment_id=")
                if (urlParts.length > 1) {
                    paymentId = parseInt(urlParts[1]) || paymentId
                }
                
                // Simulate payment notification
                var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
                apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
            } else if (paymentId > 0) {
                // 如果没有redirect_url，直接模拟支付
                var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
                apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
            }
        }

        function onPaymentNotified(response) {
            if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                statusText.text = "支付成功！"
                statusText.color = "green"
                Qt.callLater(function() {
                    if (stackView) {
                        stackView.pop()
                    }
                })
            } else {
                statusText.text = response.message || "支付失败"
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                var errorMsg = response.error || response.message || "未知错误"
                console.log("Payment error:", errorMsg)
                
                // 如果是订单类型错误，尝试其他类型
                if (errorMsg.indexOf("订单不存在") >= 0 || errorMsg.indexOf("停车记录不存在") >= 0 || errorMsg.indexOf("违规记录不存在") >= 0) {
                    // 尝试其他订单类型
                    if (orderType === "reservation") {
                        // 先尝试parking
                        console.log("Reservation not found, trying parking type")
                        orderType = "parking"
                        apiClient.createPayment(orderId, orderType, paymentMethod, amount)
                        return
                    } else if (orderType === "parking") {
                        // 再尝试violation
                        console.log("Parking not found, trying violation type")
                        orderType = "violation"
                        apiClient.createPayment(orderId, orderType, paymentMethod, amount)
                        return
                    }
                }
                
                statusText.text = errorMsg
                statusText.color = "red"
                return
            }

            var url = response.url || ""
            
            if (url.indexOf("/payment/create") >= 0) {
                if (response.hasOwnProperty("code") && response.code === 0) {
                    // Payment created successfully
                    paymentId = response.payment_id || response.paymentId || 0
                    var redirectUrl = ""
                    if (response.data && response.data.redirect_url) {
                        redirectUrl = response.data.redirect_url
                    } else if (response.redirect_url) {
                        redirectUrl = response.redirect_url
                    }
                    
                    if (redirectUrl.length > 0) {
                        // Extract payment_id from URL if needed
                        var urlParts = redirectUrl.split("payment_id=")
                        if (urlParts.length > 1) {
                            var extractedId = parseInt(urlParts[1].split("&")[0])
                            if (extractedId > 0) {
                                paymentId = extractedId
                            }
                        }
                    }
                    
                    console.log("Payment created, paymentId:", paymentId)
                    
                    if (paymentId > 0) {
                        // Simulate payment
                        statusText.text = "支付创建成功，正在处理支付..."
                        statusText.color = "blue"
                        var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
                        apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
                    } else {
                        statusText.text = "创建支付失败：未获取到支付ID"
                        statusText.color = "red"
                    }
                } else {
                    var errorMsg = response.message || "创建支付失败"
                    console.log("Payment creation failed:", errorMsg)
                    statusText.text = errorMsg
                    statusText.color = "red"
                }
            } else if (url.indexOf("/payment/notify") >= 0) {
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                    statusText.text = "支付成功！"
                    statusText.color = "green"
                    Qt.callLater(function() {
                        if (stackView) {
                            stackView.pop()
                        }
                    })
                } else {
                    statusText.text = response.message || "支付失败"
                    statusText.color = "red"
                }
            } else if (url.indexOf("/violations/") >= 0 && url.indexOf("/pay") >= 0) {
                // 违规罚款支付创建成功
                if (response.payment_id || response.paymentId) {
                    paymentId = response.payment_id || response.paymentId
                    var redirectUrl = response.payment_url || response.redirect_url || ""
                    if (redirectUrl.length > 0) {
                        var urlParts = redirectUrl.split("payment_id=")
                        if (urlParts.length > 1) {
                            paymentId = parseInt(urlParts[1].split("&")[0]) || paymentId
                        }
                    }
                    if (paymentId > 0) {
                        statusText.text = "支付创建成功，正在处理支付..."
                        statusText.color = "blue"
                        var transactionNo = "TXN" + Date.now() + Math.floor(Math.random() * 1000)
                        apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
                    }
                }
            }
        }
    }
}

