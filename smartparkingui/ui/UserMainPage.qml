import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    id: userMainPage
    title: "用户中心"

    property int userId: 0
    property string currentLicensePlate: ""
    signal logout()

    TabBar {
        id: tabBar
        width: parent.width

        TabButton { text: "停车状态" }
        TabButton { text: "预订信息" }
        TabButton { text: "订单历史" }
        TabButton { text: "违规记录" }
    }

    StackLayout {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: tabBar.currentIndex

        // Parking Status Tab
        ScrollView {
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "当前停车状态"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 150
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                id: parkingStatusText
                                text: "加载中..."
                                font.pixelSize: 16
                            }

                            Text {
                                id: parkingInfoText
                                text: ""
                                font.pixelSize: 14
                                color: "gray"
                            }

                            RowLayout {
                                Button {
                                    text: "停车"
                                    visible: parkingStatusText.text === "当前暂无车辆在使用停车场"
                                    onClicked: {
                                        // Navigate to parking entry
                                        stackView.push(parkingEntryPage)
                                    }
                                }

                                Button {
                                    text: "离开"
                                    visible: parkingStatusText.text !== "当前暂无车辆在使用停车场" && parkingStatusText.text !== "加载中..."
                                    onClicked: {
                                        if (currentLicensePlate.length > 0) {
                                            apiClient.vehicleExit(currentLicensePlate)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Booking Tab
        ScrollView {
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    RowLayout {
                        Text {
                            text: "预订信息"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "新建预订"
                            onClicked: {
                                stackView.push(bookingPage)
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 400
                        model: bookingModel
                        delegate: bookingDelegate
                    }
                }
            }
        }

        // Order History Tab
        ScrollView {
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "订单历史"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 500
                        model: paymentModel
                        delegate: paymentDelegate
                    }
                }
            }
        }

        // Violation Tab
        ScrollView {
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "违规记录"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 500
                        model: violationModel
                        delegate: violationDelegate
                    }
                }
            }
        }
    }

    // Models
    ListModel {
        id: bookingModel
    }

    ListModel {
        id: paymentModel
    }

    ListModel {
        id: violationModel
    }

    // Delegates
    Component {
        id: bookingDelegate
        Rectangle {
            width: ListView.view.width
            height: 100
            border.color: "gray"
            border.width: 1
            radius: 5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                Text { text: "预订编号: " + (model.reservationCode || "") }
                Text { text: "状态: " + getStatusText(model.status) }
                Text { text: "时间: " + (model.startTime || "") + " - " + (model.endTime || "") }
            }
        }
    }

    Component {
        id: paymentDelegate
        Rectangle {
            width: ListView.view.width
            height: 80
            border.color: "gray"
            border.width: 1
            radius: 5

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                Text { text: "订单ID: " + model.orderId }
                Text { text: "金额: ¥" + model.amount }
                Text { text: "状态: " + (model.paymentStatus === 1 ? "已支付" : "待支付") }
                Item { Layout.fillWidth: true }
                Button {
                    text: "支付"
                    visible: model.paymentStatus === 0
                    onClicked: {
                        // Navigate to payment page
                        stackView.push(paymentPage, {
                            orderId: model.orderId,
                            type: "parking",
                            amount: model.amount
                        })
                    }
                }
            }
        }
    }

    Component {
        id: violationDelegate
        Rectangle {
            width: ListView.view.width
            height: 100
            border.color: "gray"
            border.width: 1
            radius: 5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                Text { text: "违规类型: " + (model.violationType || "") }
                Text { text: "罚款金额: ¥" + (model.fineAmount || 0) }
                Text { text: "状态: " + (model.status === 1 ? "已处理" : "未处理") }
                Button {
                    text: "支付罚款"
                    visible: model.status === 0
                    onClicked: {
                        apiClient.payViolationFine(model.violationId)
                    }
                }
            }
        }
    }

    function getStatusText(status) {
        switch(status) {
            case 0: return "已取消"
            case 1: return "已预订"
            case 2: return "使用中"
            case 3: return "已完成"
            default: return "未知"
        }
    }

    Component.onCompleted: {
        loadParkingStatus()
        loadBookings()
        loadPaymentRecords()
        loadViolations()
    }

    function loadParkingStatus() {
        apiClient.getUserActiveParkingRecords(userId)
    }

    function loadBookings() {
        apiClient.getUserBookings(userId)
    }

    function loadPaymentRecords() {
        apiClient.getUserPaymentRecords(1, 20)
    }

    function loadViolations() {
        apiClient.getUserViolations(userId)
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            // Handle different response types
            if (response.hasOwnProperty("data") && Array.isArray(response.data)) {
                // Handle array responses
                if (response.data.length > 0 && response.data[0].hasOwnProperty("record_id")) {
                    // Parking records
                    var record = response.data[0]
                    var statusText = "当前有车辆停在停车场"
                    var infoText = "车牌号: " + (record.vehicle?.license_plate || "") + "\n" +
                                  "停车场: " + (record.lot?.name || "") + "\n" +
                                  "入场时间: " + (record.entry_time || "")
                    parkingStatusText.text = statusText
                    parkingInfoText.text = infoText
                    currentLicensePlate = record.vehicle?.license_plate || ""
                }
            }
        }

        function onActiveParkingRecordsReceived(records) {
            bookingModel.clear()
            for (var i = 0; i < records.length; i++) {
                bookingModel.append(records[i])
            }
        }

        function onPaymentRecordsReceived(response) {
            paymentModel.clear()
            var records = response.records || []
            for (var i = 0; i < records.length; i++) {
                paymentModel.append(records[i])
            }
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            Text {
                text: "智能停车系统 - 用户中心"
                font.pixelSize: 18
            }
            Item { Layout.fillWidth: true }
            Button {
                text: "退出登录"
                onClicked: logout()
            }
        }
    }
}

