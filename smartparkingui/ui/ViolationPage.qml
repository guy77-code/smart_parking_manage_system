import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: violationPage
    title: "违规记录"

    property int userId: 0
    property var stackView: null
    property int currentViolationId: 0
    
    property string statusText: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "返回"
                onClicked: {
                    // 违规记录页目前一般从用户主页面的 Tab 打开，
                    // 如后续通过 StackView 独立打开，可在这里接入 stackView.pop()
                    Qt.callLater(function() {
                        // 占位：无需返回时不做任何操作
                    })
                }
            }
            Item { Layout.fillWidth: true }
        }

        Text {
            text: "违规记录"
            font.pixelSize: 24
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: violationModel
            delegate: Rectangle {
                width: ListView.view.width
                height: 120
                border.color: "gray"
                border.width: 1
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Text {
                        text: "违规类型: " + (model.violationType || "")
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: "违规时间: " + (model.violationTime || "")
                        font.pixelSize: 14
                    }

                    Text {
                        text: "罚款金额: ¥" + (model.fineAmount || 0).toFixed(2)
                        font.pixelSize: 14
                        color: "red"
                    }

                    Text {
                        text: "状态: " + (model.status === 1 ? "已处理" : "未处理")
                        font.pixelSize: 14
                        color: model.status === 1 ? "green" : "orange"
                    }

                    RowLayout {
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "处理罚单"
                            visible: model.status === 0
                            onClicked: {
                                // 跳转到支付页面
                                var violationId = model.violationId || model.violation_id || 0
                                var fineAmount = model.fineAmount || model.fine_amount || 0
                                
                                console.log("Processing violation:", violationId, "Amount:", fineAmount)
                                
                                if (violationId > 0 && stackView) {
                                    // 直接跳转到支付页面，支付页面会创建支付
                                    stackView.push(Qt.resolvedUrl("PaymentPage.qml"), {
                                        orderId: violationId,
                                        orderType: "violation",
                                        amount: fineAmount,
                                        stackView: stackView
                                    })
                                } else if (violationId > 0) {
                                    // 如果没有stackView，使用旧的API方式
                                    currentViolationId = violationId
                                    statusText = ""
                                    apiClient.payViolationFine(violationId)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: violationModel
    }

    Component.onCompleted: {
        loadViolations()
    }
    
    function loadViolations() {
        apiClient.getUserViolations(userId)
    }

    Connections {
        target: apiClient

        function onViolationsReceived(response) {
            violationModel.clear()
            console.log("Violations response:", JSON.stringify(response))
            
            var data = response.data || []
            if (Array.isArray(data)) {
                console.log("Processing", data.length, "violation records")
                for (var i = 0; i < data.length; i++) {
                    var record = data[i]
                    if (record && typeof record === 'object') {
                        console.log("Violation record:", JSON.stringify(record))
                        
                        // 处理字段名兼容性，确保正确提取违规类型和罚款金额
                        var violationType = record.violation_type !== undefined ? record.violation_type : 
                                          (record.violationType !== undefined ? record.violationType : "")
                        var fineAmount = record.fine_amount !== undefined ? parseFloat(record.fine_amount) : 
                                        (record.fineAmount !== undefined ? parseFloat(record.fineAmount) : 0)
                        var violationId = record.violation_id !== undefined ? record.violation_id : 
                                         (record.violationId !== undefined ? record.violationId : 0)
                        var violationTime = record.violation_time !== undefined ? record.violation_time : 
                                           (record.violationTime !== undefined ? record.violationTime : "")
                        var status = record.status !== undefined ? record.status : 0
                        
                        console.log("Extracted - Type:", violationType, "Amount:", fineAmount, "ID:", violationId)
                        
                        violationModel.append({
                            violationId: violationId,
                            violation_id: violationId,
                            violationType: violationType,
                            violation_type: violationType,
                            violationTime: violationTime,
                            violation_time: violationTime,
                            fineAmount: fineAmount,
                            fine_amount: fineAmount,
                            status: status,
                            description: record.description || ""
                        })
                    }
                }
            } else {
                console.log("Warning: violations data is not an array:", typeof data)
            }
            
            console.log("Loaded violations count:", violationModel.count)
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                var url = response.url || ""
                if (url.indexOf("/violations/") >= 0 && url.indexOf("/pay") >= 0) {
                    statusText.text = "创建支付失败: " + (response.error || response.message || "未知错误")
                    statusText.visible = true
                }
                return
            }

            var url = response.url || ""
            if (url.indexOf("/violations/checkmyself") >= 0) {
                var data = response.data || []
                if (Array.isArray(data)) {
                    violationModel.clear()
                    for (var i = 0; i < data.length; i++) {
                        var record = data[i]
                        if (record && typeof record === 'object') {
                            // 处理字段名兼容性
                            violationModel.append({
                                violationId: record.violation_id !== undefined ? record.violation_id : (record.violationId || 0),
                                violation_id: record.violation_id !== undefined ? record.violation_id : (record.violationId || 0),
                                violationType: record.violation_type !== undefined ? record.violation_type : (record.violationType || ""),
                                violation_type: record.violation_type !== undefined ? record.violation_type : (record.violationType || ""),
                                violationTime: record.violation_time !== undefined ? record.violation_time : (record.violationTime || ""),
                                violation_time: record.violation_time !== undefined ? record.violation_time : (record.violationTime || ""),
                                fineAmount: record.fine_amount !== undefined ? record.fine_amount : (record.fineAmount || 0),
                                fine_amount: record.fine_amount !== undefined ? record.fine_amount : (record.fineAmount || 0),
                                status: record.status !== undefined ? record.status : 0,
                                description: record.description || ""
                            })
                        }
                    }
                }
            } else if (url.indexOf("/violations/") >= 0 && url.indexOf("/pay") >= 0) {
                // 支付罚款创建成功，跳转到支付页面
                var paymentId = response.payment_id || response.paymentId || 0
                var redirectUrl = response.payment_url || response.redirect_url || ""
                
                // 从URL中提取payment_id
                if (redirectUrl.length > 0) {
                    var urlParts = redirectUrl.split("payment_id=")
                    if (urlParts.length > 1) {
                        var extractedId = parseInt(urlParts[1].split("&")[0])
                        if (extractedId > 0) {
                            paymentId = extractedId
                        }
                    }
                }
                
                if (stackView && paymentId > 0) {
                    // 找到对应的违规记录以获取金额
                    var violationAmount = 0
                    for (var i = 0; i < violationModel.count; i++) {
                        var v = violationModel.get(i)
                        var vId = v.violationId || v.violation_id || 0
                        if (vId === currentViolationId) {
                            violationAmount = v.fineAmount || v.fine_amount || 0
                            break
                        }
                    }
                    
                    // 跳转到支付页面
                    stackView.push(Qt.resolvedUrl("PaymentPage.qml"), {
                        orderId: currentViolationId,
                        orderType: "violation",
                        amount: violationAmount,
                        paymentId: paymentId,
                        stackView: stackView
                    })
                }
            } else if (url.indexOf("/payment/notify") >= 0) {
                // 支付成功，刷新违规记录列表
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                    console.log("Payment successful, refreshing violations")
                    loadViolations()
                }
            }
        }
    }
    
    // 状态提示
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: 10
        text: statusText
        color: "red"
        visible: statusText.length > 0
    }
}

