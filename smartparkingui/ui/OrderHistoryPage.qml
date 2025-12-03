import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: orderHistoryPage
    title: "订单历史"

    property var stackView: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "返回"
                onClicked: {
                    if (stackView) {
                        stackView.pop()
                    } else {
                        console.log("stackView is null, cannot pop OrderHistoryPage")
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        Text {
            text: "订单历史"
            font.pixelSize: 24
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: paymentModel
            delegate: Rectangle {
                width: ListView.view.width
                height: 100
                border.color: "gray"
                border.width: 1
                radius: 5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ColumnLayout {
                        Text {
                            text: "订单ID: " + model.orderId
                            font.pixelSize: 14
                        }
                        Text {
                            text: "金额: ¥" + (model.amount || 0).toFixed(2)
                            font.pixelSize: 14
                        }
                        Text {
                            text: "支付方式: " + (model.method || "")
                            font.pixelSize: 12
                            color: "gray"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        Text {
                            text: model.paymentStatus === 1 ? "已支付" : "待支付"
                            font.pixelSize: 14
                            color: model.paymentStatus === 1 ? "green" : "orange"
                        }
                        Text {
                            text: model.payTime || ""
                            font.pixelSize: 12
                            color: "gray"
                        }
                    }

                    Button {
                        text: "支付"
                        visible: model.paymentStatus === 0
                        onClicked: {
                            if (stackView) {
                                // 从订单信息中判断类型
                                // 如果订单信息中有order字段，可以从中判断类型
                                var orderType = "reservation"  // 默认类型
                                
                                // 尝试从订单信息中获取类型提示
                                // 注意：PaymentRecord的order_id可能对应reservation、parking或violation
                                // 这里简化处理，优先尝试reservation，如果失败可以重试其他类型
                                
                                var orderId = model.orderId || model.order_id || 0
                                var amount = model.amount || 0
                                
                                console.log("Payment button clicked - OrderID:", orderId, "Amount:", amount)
                                
                                // 跳转到支付页面，让用户选择支付方式
                                stackView.push(Qt.resolvedUrl("PaymentPage.qml"), {
                                    orderId: orderId,
                                    orderType: orderType,  // 默认reservation，支付页面会尝试创建支付
                                    amount: amount,
                                    stackView: stackView
                                })
                            } else {
                                console.log("stackView is null, cannot navigate to PaymentPage")
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: paymentModel
    }

    Component.onCompleted: {
        apiClient.getUserPaymentRecords(1, 50)
    }

    Connections {
        target: apiClient

        function onPaymentRecordsReceived(response) {
            paymentModel.clear()
            var records = response.records || []
            for (var i = 0; i < records.length; i++) {
                var record = records[i]
                if (record && typeof record === 'object') {
                    // 处理字段名兼容性
                    paymentModel.append({
                        paymentId: record.payment_id !== undefined ? record.payment_id : (record.paymentId || 0),
                        payment_id: record.payment_id !== undefined ? record.payment_id : (record.paymentId || 0),
                        orderId: record.order_id !== undefined ? record.order_id : (record.orderId || 0),
                        order_id: record.order_id !== undefined ? record.order_id : (record.orderId || 0),
                        amount: record.amount || 0,
                        method: record.method || "",
                        paymentStatus: record.payment_status !== undefined ? record.payment_status : (record.paymentStatus || 0),
                        payment_status: record.payment_status !== undefined ? record.payment_status : (record.paymentStatus || 0),
                        payTime: record.pay_time !== undefined ? record.pay_time : (record.payTime || ""),
                        pay_time: record.pay_time !== undefined ? record.pay_time : (record.payTime || "")
                    })
                }
            }
        }

        function onRequestFinished(response) {
            var url = response.url || ""
            // 支付成功后刷新订单列表
            if (url.indexOf("/payment/notify") >= 0) {
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                    console.log("Payment successful, refreshing payment records")
                    apiClient.getUserPaymentRecords(1, 50)
                }
            }
        }
    }
}

