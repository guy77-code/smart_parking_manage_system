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
                                        // 导航到车辆入场页面
                                        if (stackView) {
                                            stackView.push(Qt.resolvedUrl("ParkingEntryPage.qml"), {
                                                               userId: userId,
                                                               stackView: stackView
                                                           })
                                        } else {
                                            console.log("stackView is null, cannot navigate to ParkingEntryPage")
                                        }
                                    }
                                }

                                Button {
                                    text: "离开"
                                    visible: parkingStatusText.text !== "当前暂无车辆在使用停车场" && parkingStatusText.text !== "加载中..."
                                    onClicked: {
                                        console.log("Vehicle exit clicked, license plate:", currentLicensePlate)
                                        if (currentLicensePlate.length > 0) {
                                            console.log("Calling vehicleExit with:", currentLicensePlate)
                                            apiClient.vehicleExit(currentLicensePlate)
                                        } else {
                                            console.log("License plate is empty, cannot exit")
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
                                if (stackView) {
                                    stackView.push(Qt.resolvedUrl("BookingPage.qml"), {
                                                       userId: userId,
                                                       stackView: stackView
                                                   })
                                } else {
                                    console.log("stackView is null, cannot navigate to BookingPage")
                                }
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
                Text { 
                    text: "预订编号: " + (model.reservationCode || model.reservation_code || model.reservation_cod || "")
                    font.pixelSize: 14
                }
                Text { 
                    text: "状态: " + getStatusText(model.status)
                    font.pixelSize: 14
                }
                Text { 
                    text: "时间: " + (model.startTime || model.start_time || "") + " - " + (model.endTime || model.end_time || "")
                    font.pixelSize: 12
                    color: "gray"
                }
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
                        if (stackView) {
                            stackView.push(Qt.resolvedUrl("PaymentPage.qml"), {
                                               orderId: model.orderId,
                                               type: "parking",
                                               amount: model.amount,
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

    Component {
        id: violationDelegate
        Rectangle {
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
                    text: "违规类型: " + (model.violationType || model.violation_type || "")
                    font.pixelSize: 14
                    font.bold: true
                }
                Text { 
                    text: "罚款金额: ¥" + ((model.fineAmount || model.fine_amount || 0).toFixed(2))
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
                            var violationId = model.violationId || model.violation_id || 0
                            var fineAmount = model.fineAmount || model.fine_amount || 0
                            
                            if (violationId > 0 && stackView) {
                                stackView.push(Qt.resolvedUrl("PaymentPage.qml"), {
                                    orderId: violationId,
                                    orderType: "violation",
                                    amount: fineAmount,
                                    stackView: stackView
                                })
                            } else if (violationId > 0) {
                                apiClient.payViolationFine(violationId)
                            }
                        }
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
            var url = response.url || ""
            console.log("Request finished, URL:", url)

            // 统一错误处理（包括 HTTP 非 2xx 和网络层错误）
            var httpStatus = response.http_status !== undefined ? response.http_status : 200
            if (response.hasOwnProperty("error") && httpStatus !== 404) {
                console.log("Error:", response.error)
                // 对于停车状态，404 表示无在场记录，不当作错误
                if (url.indexOf("/active-parking") < 0) {
                    return
                }
            }

            // Handle active parking records response
            if (url.indexOf("/active-parking") >= 0) {
                console.log("Active parking records response:", JSON.stringify(response))

                // Handle parking records data
                var data = response.data || []
                if (Array.isArray(data) && data.length > 0) {
                    var record = data[0]
                    console.log("Parking record:", JSON.stringify(record))

                    // 尽可能鲁棒地提取车牌号
                    var licensePlate = ""
                    if (record.vehicle) {
                        licensePlate = record.vehicle.license_plate || record.vehicle.licensePlate || ""
                        if (!licensePlate) {
                            // 在 vehicle 对象里兜底查找包含 "license" 的字段
                            for (var vk in record.vehicle) {
                                if (typeof record.vehicle[vk] === "string" && vk.toLowerCase().indexOf("license") >= 0) {
                                    licensePlate = record.vehicle[vk]
                                    break
                                }
                            }
                        }
                    }
                    // 也检查是否直接在 record 中带有车牌字段
                    if (!licensePlate && record.license_plate) {
                        licensePlate = record.license_plate
                    }
                    if (!licensePlate && record.licensePlate) {
                        licensePlate = record.licensePlate
                    }
                    if (!licensePlate) {
                        // 再兜底一层：在 record 所有字段中搜索类似车牌的字段
                        for (var rk in record) {
                            if (typeof record[rk] === "string" && rk.toLowerCase().indexOf("license") >= 0) {
                                licensePlate = record[rk]
                                break
                            }
                        }
                    }

                    console.log("Extracted license plate:", licensePlate)

                    var lotName = ""
                    if (record.lot) {
                        lotName = record.lot.name || record.lot.lot_name || ""
                    }
                    if (!lotName) {
                        lotName = record.lot_name || ""
                    }

                    var entryTime = record.entry_time || record.entryTime || ""

                    var statusText = "当前有车辆停在停车场"
                    var infoText = "车牌号: " + (licensePlate || "未知") + "\n" +
                                  "停车场: " + (lotName || "未知") + "\n" +
                                  "入场时间: " + (entryTime || "未知")
                    parkingStatusText.text = statusText
                    parkingInfoText.text = infoText
                    currentLicensePlate = licensePlate || ""
                    console.log("Set currentLicensePlate to:", currentLicensePlate)
                } else {
                    // No active parking records
                    console.log("No active parking records")
                    parkingStatusText.text = "当前暂无车辆在使用停车场"
                    parkingInfoText.text = ""
                    currentLicensePlate = ""
                }
                return
            }

            // Handle vehicle exit response
            if (url.indexOf("/api/parking/exit") >= 0) {
                if (response.hasOwnProperty("error")) {
                    console.log("Vehicle exit error:", response.error)
                    return
                }
                // Vehicle exit successful, refresh parking status
                parkingStatusText.text = "当前暂无车辆在使用停车场"
                parkingInfoText.text = ""
                currentLicensePlate = ""
                // Reload parking status
                loadParkingStatus()
                return
            }

            // Handle booking/user response
            if (url.indexOf("/api/v4/booking/user") >= 0) {
                bookingModel.clear()
                var data = response.data || []
                if (Array.isArray(data)) {
                    for (var i = 0; i < data.length; i++) {
                        var record = data[i]
                        // Filter out null values and create clean record
                        if (record && typeof record === 'object') {
                            var cleanRecord = {}
                            // 处理字段名兼容性
                            cleanRecord.orderId = record.order_id !== undefined ? record.order_id : (record.orderId || 0)
                            cleanRecord.order_id = cleanRecord.orderId
                            cleanRecord.reservationCode = record.reservation_code !== undefined ? record.reservation_code : (record.reservationCode || record.reservation_cod || "")
                            cleanRecord.reservation_code = cleanRecord.reservationCode
                            cleanRecord.startTime = record.start_time !== undefined ? record.start_time : (record.startTime || "")
                            cleanRecord.start_time = cleanRecord.startTime
                            cleanRecord.endTime = record.end_time !== undefined ? record.end_time : (record.endTime || "")
                            cleanRecord.end_time = cleanRecord.endTime
                            cleanRecord.status = record.status !== undefined ? record.status : 0
                            cleanRecord.totalFee = record.total_fee !== undefined ? record.total_fee : (record.totalFee || 0)
                            cleanRecord.total_fee = cleanRecord.totalFee
                            cleanRecord.paymentStatus = record.payment_status !== undefined ? record.payment_status : (record.paymentStatus || 0)
                            cleanRecord.payment_status = cleanRecord.paymentStatus
                            
                            bookingModel.append(cleanRecord)
                        }
                    }
                }
                return
            }
            
            // Handle payment notification - refresh violations and payment records
            if (url.indexOf("/payment/notify") >= 0) {
                if (response.code === 0 || (response.code === undefined && !response.hasOwnProperty("error"))) {
                    console.log("Payment successful, refreshing violations and payment records")
                    loadViolations()
                    loadPaymentRecords()
                }
                return
            }

        }

        function onActiveParkingRecordsReceived(records) {
            // This is for parking records, not bookings
            // Parking records are handled in onRequestFinished
        }

        function onPaymentRecordsReceived(response) {
            paymentModel.clear()
            var records = response.records || []
            for (var i = 0; i < records.length; i++) {
                var record = records[i]
                // Filter out null values and create clean record
                if (record && typeof record === 'object') {
                    var cleanRecord = {}
                    for (var key in record) {
                        if (record[key] !== null && record[key] !== undefined) {
                            cleanRecord[key] = record[key]
                        } else {
                            // Set default values for null fields
                            if (key === 'orderId') cleanRecord[key] = 0
                            else if (key === 'amount') cleanRecord[key] = 0
                            else if (key === 'paymentStatus') cleanRecord[key] = 0
                            else cleanRecord[key] = ""
                        }
                    }
                    paymentModel.append(cleanRecord)
                }
            }
        }

        function onViolationsReceived(response) {
            violationModel.clear()
            console.log("Violations response in UserMainPage:", JSON.stringify(response))
            
            var data = response.data || []
            if (Array.isArray(data)) {
                for (var i = 0; i < data.length; i++) {
                    var record = data[i]
                    if (record && typeof record === 'object') {
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

