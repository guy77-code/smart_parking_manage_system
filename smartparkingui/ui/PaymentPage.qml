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
            text: "确认支付"
            enabled: orderId > 0 && amount > 0
            onClicked: {
                // Create payment first
                apiClient.createPayment(orderId, orderType, paymentMethod, amount)
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
            paymentId = payment.payment_id || 0
            var redirectUrl = payment.data?.redirect_url || ""
            
            if (redirectUrl.length > 0) {
                // Extract payment_id from URL if needed
                var urlParts = redirectUrl.split("payment_id=")
                if (urlParts.length > 1) {
                    paymentId = parseInt(urlParts[1]) || paymentId
                }
                
                // Simulate payment notification
                var transactionNo = "TXN" + Date.now()
                apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
            }
        }

        function onPaymentNotified(response) {
            if (response.code === 0) {
                statusText.text = "支付成功！"
                statusText.color = "green"
                Qt.callLater(function() {
                    stackView.pop()
                })
            } else {
                statusText.text = response.message || "支付失败"
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                statusText.text = response.error
                return
            }

            if (response.hasOwnProperty("code")) {
                if (response.code === 0 && response.hasOwnProperty("payment_id")) {
                    // Payment created
                    paymentId = response.payment_id
                    var redirectUrl = response.data?.redirect_url || ""
                    
                    if (redirectUrl.length > 0) {
                        // Simulate payment
                        var transactionNo = "TXN" + Date.now()
                        apiClient.notifyPayment(paymentId, amount, transactionNo, paymentMethod)
                    }
                } else {
                    statusText.text = response.message || "操作失败"
                }
            }
        }
    }
}

