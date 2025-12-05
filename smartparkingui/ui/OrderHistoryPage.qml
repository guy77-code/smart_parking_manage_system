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

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "订单历史"
                font.pixelSize: 24
                font.bold: true
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "刷新"
                onClicked: {
                    apiClient.getUserPaymentRecords(1, 50)
                }
            }
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: paymentModel
            delegate: Rectangle {
                width: ListView.view.width
                height: orderDetailsText.visible ? 200 : 120
                border.color: "gray"
                border.width: 1
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // 第一行：订单类型和基本信息
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: getOrderTypeLabel(model.orderType || model.order_type || model.orderTypeHint || "")
                                font.pixelSize: 16
                                font.bold: true
                                color: getOrderTypeColor(model.orderType || model.order_type || model.orderTypeHint || "")
                            }

                            Text {
                                text: "订单ID: " + model.orderId
                                font.pixelSize: 12
                                color: "gray"
                            }

                            Text {
                                text: "金额: ¥" + (model.amount || 0).toFixed(2)
                                font.pixelSize: 14
                                font.bold: true
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: model.paymentStatus === 1 ? "已支付" : "待支付"
                                font.pixelSize: 14
                                color: model.paymentStatus === 1 ? "green" : "orange"
                                font.bold: true
                            }
                            // 显示预订状态（仅对预订订单）
                            Text {
                                text: getReservationStatusText(model)
                                font.pixelSize: 12
                                color: getReservationStatusColor(model)
                                visible: text.length > 0
                            }
                            Text {
                                text: model.payTime || ""
                                font.pixelSize: 11
                                color: "gray"
                            }
                        }

                        Button {
                            text: "支付"
                            visible: model.paymentStatus === 0
                            onClicked: {
                                if (stackView) {
                                    var orderId = model.orderId || model.order_id || 0
                                    var amount = model.amount || 0
                                    var orderType = model.orderType || model.order_type || model.orderTypeHint || ""
                                    console.log("Payment button clicked - OrderID:", orderId, "Amount:", amount, "Type:", orderType)
                                    var sequence = []
                                    if (orderType && orderType.length > 0) {
                                        sequence.push(orderType)
                                    }
                                    var defaults = ["reservation", "parking", "violation"]
                                    for (var i = 0; i < defaults.length; i++) {
                                        if (sequence.indexOf(defaults[i]) < 0) {
                                            sequence.push(defaults[i])
                                        }
                                    }
                                    var chosenType = sequence.length > 0 ? sequence[0] : "reservation"
                                    stackView.push(Qt.resolvedUrl("PaymentPage.qml"), {
                                        orderId: orderId,
                                        orderType: chosenType,
                                        orderTypeSequence: sequence,
                                        amount: amount,
                                        stackView: stackView,
                                        onPaymentSucceeded: function(type, paidOrderId) {
                                            console.log("Payment succeeded for order:", paidOrderId)
                                            // 延迟刷新，确保后端数据已更新
                                            Qt.callLater(function() {
                                                apiClient.getUserPaymentRecords(1, 50)
                                            })
                                        }
                                    })
                                } else {
                                    console.log("stackView is null, cannot navigate to PaymentPage")
                                }
                            }
                        }
                    }

                    // 第二行：订单详细信息
                    Text {
                        id: orderDetailsText
                        Layout.fillWidth: true
                        text: getOrderDetailsText(model)
                        font.pixelSize: 12
                        color: "gray"
                        wrapMode: Text.Wrap
                        visible: text.length > 0
                    }
                }
            }
        }

        function getOrderTypeLabel(orderType) {
            if (orderType === "parking") return "停车订单"
            if (orderType === "violation") return "违规订单"
            if (orderType === "reservation") return "预订订单"
            return "订单"
        }

        function getOrderTypeColor(orderType) {
            if (orderType === "parking") return "blue"
            if (orderType === "violation") return "red"
            if (orderType === "reservation") return "green"
            return "black"
        }

        function getReservationStatusText(record) {
            var orderType = record.orderType || record.order_type || record.orderTypeHint || ""
            // 只对预订订单显示状态
            if (orderType !== "reservation") return ""
            
            var details = record.orderDetails || record.order_details || {}
            var status = details.status
            
            if (status === undefined || status === null) return ""
            
            // 预订状态：0-已取消，1-已预订，2-使用中，3-已完成
            if (status === 0) return "状态: 已取消"
            if (status === 1) return "状态: 已预订"
            if (status === 2) return "状态: 使用中"
            if (status === 3) return "状态: 已完成"
            
            return ""
        }

        function getReservationStatusColor(record) {
            var details = record.orderDetails || record.order_details || {}
            var status = details.status
            
            if (status === undefined || status === null) return "gray"
            
            if (status === 0) return "red"      // 已取消
            if (status === 1) return "orange"    // 已预订
            if (status === 2) return "blue"     // 使用中
            if (status === 3) return "green"    // 已完成
            
            return "gray"
        }

        function getOrderDetailsText(record) {
            var details = record.orderDetails || record.order_details || {}
            var orderType = record.orderType || record.order_type || record.orderTypeHint || ""
            var text = ""

            if (orderType === "parking") {
                // 停车订单详情
                var lot = details.lot || {}
                var vehicle = details.vehicle || {}
                var entryTime = details.entry_time || details.entryTime || ""
                var exitTime = details.exit_time || details.exitTime || ""
                var durationMinute = details.duration_minute !== undefined ? details.duration_minute : (details.durationMinute || 0)
                
                // 显示停车时长
                if (durationMinute > 0) {
                    var hours = Math.floor(durationMinute / 60)
                    var minutes = durationMinute % 60
                    if (hours > 0 && minutes > 0) {
                        text = "停车时长: " + hours + "小时" + minutes + "分钟\n"
                    } else if (hours > 0) {
                        text = "停车时长: " + hours + "小时\n"
                    } else {
                        text = "停车时长: " + minutes + "分钟\n"
                    }
                } else if (entryTime && exitTime) {
                    // 如果没有duration_minute，尝试计算
                    text = "停车时间: " + formatDateTime(entryTime) + " 至 " + formatDateTime(exitTime) + "\n"
                } else if (entryTime) {
                    text = "入场时间: " + formatDateTime(entryTime) + "\n"
                }
                
                // 显示停车场地点
                if (lot.name) {
                    text += "停车场: " + lot.name
                    if (lot.address) {
                        text += " (" + lot.address + ")"
                    }
                    text += "\n"
                }
                
                // 显示停车车辆信息
                if (vehicle.license_plate || vehicle.licensePlate) {
                    text += "车辆: " + (vehicle.license_plate || vehicle.licensePlate)
                    var vehicleInfo = []
                    if (vehicle.brand) vehicleInfo.push(vehicle.brand)
                    if (vehicle.model) vehicleInfo.push(vehicle.model)
                    if (vehicle.color) vehicleInfo.push(vehicle.color)
                    if (vehicleInfo.length > 0) {
                        text += " (" + vehicleInfo.join(" ") + ")"
                    }
                }
            } else if (orderType === "violation") {
                // 违规订单详情
                var violationTime = details.violation_time || details.violationTime || ""
                var description = details.description || ""
                var violationType = details.violation_type || details.violationType || ""
                
                // 明确说明这是违规事件订单
                text = "订单类型: 违规事件订单\n"
                
                if (violationTime) {
                    text += "违规时间: " + formatDateTime(violationTime) + "\n"
                }
                
                if (violationType) {
                    text += "违规类型: " + violationType + "\n"
                }
                
                if (description) {
                    text += "违规事件: " + description
                }
            } else if (orderType === "reservation") {
                // 预订订单详情
                var reservationCod = details.reservation_cod || details.reservationCod || ""
                var startTime = details.start_time || details.startTime || ""
                var endTime = details.end_time || details.endTime || ""
                var status = details.status
                var entryTime = details.entry_time || details.entryTime || ""
                var exitTime = details.exit_time || details.exitTime || ""
                var durationMinute = details.duration_minute !== undefined ? details.duration_minute : (details.durationMinute || 0)
                
                if (reservationCod) {
                    text = "预订编号: " + reservationCod + "\n"
                }
                
                // 显示预订状态
                if (status !== undefined && status !== null) {
                    var statusText = ""
                    if (status === 0) statusText = "已取消"
                    else if (status === 1) statusText = "已预订"
                    else if (status === 2) statusText = "使用中"
                    else if (status === 3) statusText = "已完成"
                    
                    if (statusText.length > 0) {
                        text += "预订状态: " + statusText + "\n"
                    }
                }
                
                // 如果已进场或已完成，显示停车时长
                if ((status === 2 || status === 3) && durationMinute > 0) {
                    var hours = Math.floor(durationMinute / 60)
                    var minutes = durationMinute % 60
                    if (hours > 0 && minutes > 0) {
                        text += "停车时长: " + hours + "小时" + minutes + "分钟\n"
                    } else if (hours > 0) {
                        text += "停车时长: " + hours + "小时\n"
                    } else {
                        text += "停车时长: " + minutes + "分钟\n"
                    }
                } else if ((status === 2 || status === 3) && entryTime && exitTime) {
                    // 如果没有duration_minute，尝试计算
                    text += "停车时间: " + formatDateTime(entryTime) + " 至 " + formatDateTime(exitTime) + "\n"
                } else if (status === 2 && entryTime) {
                    text += "入场时间: " + formatDateTime(entryTime) + "\n"
                }
                
                if (startTime && endTime) {
                    text += "预订时间: " + formatDateTime(startTime) + " 至 " + formatDateTime(endTime)
                }
            }

            return text
        }

        function formatDateTime(dateTimeStr) {
            if (!dateTimeStr || dateTimeStr.length === 0) return ""
            // 尝试解析ISO 8601格式 (RFC3339)
            try {
                var date = new Date(dateTimeStr)
                if (isNaN(date.getTime())) return dateTimeStr
                // 格式化为本地时间字符串
                var year = date.getFullYear()
                var month = String(date.getMonth() + 1).padStart(2, '0')
                var day = String(date.getDate()).padStart(2, '0')
                var hours = String(date.getHours()).padStart(2, '0')
                var minutes = String(date.getMinutes()).padStart(2, '0')
                return year + "-" + month + "-" + day + " " + hours + ":" + minutes
            } catch (e) {
                return dateTimeStr
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
                var cleanRecord = buildCleanPaymentRecord(records[i])
                if (cleanRecord) {
                    paymentModel.append(cleanRecord)
                }
            }
        }

        function buildCleanPaymentRecord(record) {
            if (!record || typeof record !== "object")
                return null

            var cleanRecord = {
                paymentId: record.payment_id !== undefined ? record.payment_id : (record.paymentId || 0),
                orderId: record.order_id !== undefined ? record.order_id : (record.orderId || 0),
                amount: record.amount !== undefined && record.amount !== null ? record.amount : 0,
                method: record.method || "",
                paymentStatus: record.payment_status !== undefined ? record.payment_status : (record.paymentStatus || 0),
                payTime: record.pay_time || record.payTime || "",
                createTime: record.create_time || record.createTime || "",
                orderType: record.order_type || record.orderType || "",
                orderTypeHint: record.order_type || record.orderType || "",
                orderDetails: record.order_details || record.orderDetails || {}
            }

            // 兼容旧版本：如果没有order_type，尝试从order字段推断
            var orderInfo = record.order || record.Order || null
            if (!cleanRecord.orderType && orderInfo && typeof orderInfo === "object") {
                cleanRecord.orderType = "reservation"
                cleanRecord.orderTypeHint = "reservation"
                cleanRecord.orderSummary = orderInfo.reservation_cod || orderInfo.reservationCode || ""
            }

            return cleanRecord
        }

        function onRequestFinished(response) {
            var url = response.url || ""
            var httpStatus = response.http_status !== undefined ? response.http_status : 200
            
            // 支付成功后刷新订单列表
            if (url.indexOf("/payment/notify") >= 0) {
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                    console.log("Payment successful, refreshing payment records")
                    // 延迟刷新，确保支付处理完成
                    Qt.callLater(function() {
                        apiClient.getUserPaymentRecords(1, 50)
                    })
                }
            }
            
            // 处理其他API错误，但不跳转到登录页
            if (response.hasOwnProperty("error") && httpStatus >= 400) {
                var errorMsg = response.error || response.message || ""
                console.log("API error in OrderHistoryPage:", errorMsg, "URL:", url)
                // 只记录错误，不进行任何跳转操作
                // 404错误对于某些接口是正常的（如无在场停车记录），不需要特殊处理
                if (httpStatus === 401 || httpStatus === 403) {
                    console.log("Authentication error, but not navigating to login page")
                    // 不跳转到登录页，保持当前页面
                }
            }
        }
    }
}

