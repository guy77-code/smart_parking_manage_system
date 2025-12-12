import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    id: userMainPage
    title: "用户中心"

    property int userId: 0
    signal logout()

    TabBar {
        id: tabBar
        width: parent.width

        TabButton { text: "停车状态" }
        TabButton { text: "车辆管理" }
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

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "车辆停车状态"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "刷新"
                            onClicked: {
                                loadParkingStatus()
                                loadUserVehicles()
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: vehicleParkingStatusModel
                        delegate: vehicleParkingStatusDelegate
                        spacing: 10
                    }
                }
            }
        }

        // Vehicle Management Tab
        ScrollView {
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "车辆管理"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    // 添加车辆表单
                    GroupBox {
                        title: "添加车辆"
                        Layout.fillWidth: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "车牌号:"; width: 80 }
                                TextField {
                                    id: licensePlateField
                                    Layout.fillWidth: true
                                    placeholderText: "例如：粤A12345"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "品牌:"; width: 80 }
                                TextField {
                                    id: brandField
                                    Layout.fillWidth: true
                                    placeholderText: "例如：特斯拉（可选）"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "车型:"; width: 80 }
                                TextField {
                                    id: modelField
                                    Layout.fillWidth: true
                                    placeholderText: "例如：Model 3（可选）"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text { text: "颜色:"; width: 80 }
                                TextField {
                                    id: colorField
                                    Layout.fillWidth: true
                                    placeholderText: "例如：白色（可选）"
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Button {
                                    text: "添加车辆"
                                    Layout.fillWidth: true
                                    enabled: licensePlateField.text.length > 0
                                    onClicked: {
                                        console.log("Adding vehicle:", licensePlateField.text)
                                        apiClient.addUserVehicle(
                                                    licensePlateField.text.trim(),
                                                    brandField.text.trim(),
                                                    modelField.text.trim(),
                                                    colorField.text.trim())
                                    }
                                }
                            }
                        }
                    }

                    // 车辆列表
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "我的车辆"
                            font.pixelSize: 16
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "刷新"
                            onClicked: {
                                loadUserVehicles()
                            }
                        }
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: userVehicleModel
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 70
                            border.color: "gray"
                            border.width: 1
                            radius: 5

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                ColumnLayout {
                                    Text {
                                        text: {
                                            var plate = licensePlate !== undefined ? licensePlate : (license_plate || "")
                                            return "车牌号: " + plate
                                        }
                                        font.pixelSize: 14
                                        font.bold: true
                                    }
                                    Text {
                                        text: {
                                            var brandValue = brand !== undefined ? brand : (Brand || "")
                                            var modelValue = model !== undefined ? model : (Model || "")
                                            var colorValue = color !== undefined ? color : (Color || "")
                                            var parts = []
                                            if (brandValue) parts.push(brandValue)
                                            if (modelValue) parts.push(modelValue)
                                            if (colorValue) parts.push(colorValue)
                                            return parts.join(" / ")
                                        }
                                        font.pixelSize: 12
                                        color: "gray"
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Button {
                                    text: "删除"
                                    onClicked: {
                                        var vid = vehicleId !== undefined ? vehicleId : (vehicle_id || 0)
                                        if (vid > 0) {
                                            console.log("Deleting vehicle:", vid)
                                            apiClient.deleteUserVehicle(vid)
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
                            text: "刷新"
                            onClicked: {
                                loadBookings()
                            }
                        }

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

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "订单历史"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "刷新"
                            onClicked: {
                                loadPaymentRecords()
                            }
                        }
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

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "违规记录"
                            font.pixelSize: 20
                            font.bold: true
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "刷新"
                            onClicked: {
                                loadViolations()
                            }
                        }
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

    ListModel {
        id: userVehicleModel
    }

    ListModel {
        id: vehicleParkingStatusModel
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
            height: 100
            border.color: "gray"
            border.width: 1
            radius: 5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    Text { 
                        text: getOrderTypeLabelShort(model.orderType || model.order_type || model.orderTypeHint || "")
                        font.pixelSize: 14
                        font.bold: true
                        color: getOrderTypeColorShort(model.orderType || model.order_type || model.orderTypeHint || "")
                    }
                    Text { text: "订单ID: " + model.orderId; font.pixelSize: 12; color: "gray" }
                    Item { Layout.fillWidth: true }
                    Text { 
                        text: model.paymentStatus === 1 ? "已支付" : "待支付"
                        font.pixelSize: 12
                        color: model.paymentStatus === 1 ? "green" : "orange"
                    }
                    Button {
                        text: "支付"
                        visible: model.paymentStatus === 0
                        onClicked: {
                            // Navigate to payment page
                            if (stackView) {
                                var orderId = model.orderId || model.order_id || 0
                                var amount = model.amount || 0
                                var orderType = model.orderType || model.order_type || model.orderTypeHint || ""
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
                                                       loadPaymentRecords()
                                                   }
                                               })
                            } else {
                                console.log("stackView is null, cannot navigate to PaymentPage")
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "金额: ¥" + (model.amount || 0).toFixed(2); font.pixelSize: 14; font.bold: true }
                    Item { Layout.fillWidth: true }
                    Text { text: model.payTime || ""; font.pixelSize: 11; color: "gray" }
                }

                Text {
                    Layout.fillWidth: true
                    text: getOrderDetailsTextShort(model)
                    font.pixelSize: 11
                    color: "gray"
                    wrapMode: Text.Wrap
                    visible: text.length > 0
                }
            }
        }
    }

    function getOrderTypeLabelShort(orderType) {
        if (orderType === "parking") return "停车"
        if (orderType === "violation") return "违规"
        if (orderType === "reservation") return "预订"
        return "订单"
    }

    function getOrderTypeColorShort(orderType) {
        if (orderType === "parking") return "blue"
        if (orderType === "violation") return "red"
        if (orderType === "reservation") return "green"
        return "black"
    }

    function getOrderDetailsTextShort(record) {
        var details = record.orderDetails || record.order_details || {}
        var orderType = record.orderType || record.order_type || record.orderTypeHint || ""
        var text = ""

        if (orderType === "parking") {
            // 停车订单：显示停车时长、停车场地点、车辆信息
            var lot = details.lot || {}
            var vehicle = details.vehicle || {}
            var durationMinute = details.duration_minute !== undefined ? details.duration_minute : (details.durationMinute || 0)
            
            if (durationMinute > 0) {
                var hours = Math.floor(durationMinute / 60)
                var minutes = durationMinute % 60
                if (hours > 0 && minutes > 0) {
                    text = hours + "小时" + minutes + "分钟 | "
                } else if (hours > 0) {
                    text = hours + "小时 | "
                } else {
                    text = minutes + "分钟 | "
                }
            }
            
            if (lot.name) text += lot.name
            if (vehicle.license_plate || vehicle.licensePlate) {
                if (text.length > 0) text += " | "
                text += (vehicle.license_plate || vehicle.licensePlate)
            }
        } else if (orderType === "violation") {
            // 违规订单：显示违规时间和违规事件
            var violationTime = details.violation_time || details.violationTime || ""
            var description = details.description || ""
            var violationType = details.violation_type || details.violationType || ""
            
            text = "违规事件订单"
            if (violationTime) {
                // 格式化时间显示
                try {
                    var date = new Date(violationTime)
                    if (!isNaN(date.getTime())) {
                        var month = String(date.getMonth() + 1).padStart(2, '0')
                        var day = String(date.getDate()).padStart(2, '0')
                        var hours = String(date.getHours()).padStart(2, '0')
                        var minutes = String(date.getMinutes()).padStart(2, '0')
                        text += " | " + month + "-" + day + " " + hours + ":" + minutes
                    }
                } catch(e) {}
            }
            if (violationType) {
                text += " | " + violationType
            }
        } else if (orderType === "reservation") {
            var reservationCod = details.reservation_cod || details.reservationCod || ""
            if (reservationCod) text = "编号: " + reservationCod
        }

        return text
    }

    Component {
        id: vehicleParkingStatusDelegate
        Rectangle {
            width: ListView.view.width
            height: 140
            border.color: "gray"
            border.width: 1
            radius: 5

            // 在顶层定义属性，确保在整个组件中可访问
            // 直接访问模型属性，QML会自动处理绑定
            property string vehicleLicensePlate: model ? (model.licensePlate || model.license_plate || "") : ""
            property int vehicleIdValue: model ? (model.vehicleId || model.vehicle_id || 0) : 0
            property bool vehicleIsParking: model ? (model.isParking === true) : false
            
            // 调试：输出模型数据
            Component.onCompleted: {
                console.log("=== Delegate Component.onCompleted ===")
                console.log("model:", model)
                if (model) {
                    console.log("  model.licensePlate:", model.licensePlate)
                    console.log("  model.license_plate:", model.license_plate)
                    console.log("  model.vehicleId:", model.vehicleId)
                    console.log("  model.vehicle_id:", model.vehicle_id)
                    console.log("  model.isParking:", model.isParking)
                    console.log("  All model keys:", Object.keys(model))
                } else {
                    console.log("  ERROR: model is null or undefined!")
                }
                console.log("  vehicleLicensePlate:", vehicleLicensePlate)
                console.log("  vehicleIdValue:", vehicleIdValue)
                console.log("  vehicleIsParking:", vehicleIsParking)
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "车牌号: " + (vehicleLicensePlate || "未知")
                        font.pixelSize: 16
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: vehicleIsParking ? "停车中" : "未停车"
                        font.pixelSize: 14
                        color: vehicleIsParking ? "green" : "gray"
                    }
                }

                Text {
                    visible: vehicleIsParking
                    text: {
                        var info = []
                        if (model.lotName) info.push("停车场: " + model.lotName)
                        if (model.entryTime) info.push("入场时间: " + formatParkingTime(model.entryTime))
                        if (model.spaceNumber) info.push("车位: " + model.spaceNumber)
                        return info.join("\n")
                    }
                    font.pixelSize: 12
                    color: "gray"
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "停车"
                        visible: !vehicleIsParking
                        enabled: !vehicleIsParking && vehicleLicensePlate.length > 0
                        onClicked: {
                            console.log("Park button clicked:")
                            console.log("  vehicleLicensePlate:", vehicleLicensePlate)
                            console.log("  vehicleIdValue:", vehicleIdValue)
                            console.log("  stackView:", stackView)
                            
                            if (vehicleLicensePlate.length > 0 && stackView) {
                                console.log("Navigating to ParkingEntryPage with:", vehicleLicensePlate, vehicleIdValue)
                                stackView.push(Qt.resolvedUrl("ParkingEntryPage.qml"), {
                                                   userId: userId,
                                                   stackView: stackView,
                                                   preSelectedVehicleId: vehicleIdValue,
                                                   preSelectedLicensePlate: vehicleLicensePlate
                                               })
                            } else {
                                console.log("Cannot park: vehicleLicensePlate=", vehicleLicensePlate, "stackView=", stackView)
                            }
                        }
                    }
                    Button {
                        text: "离场"
                        visible: vehicleIsParking
                        enabled: vehicleIsParking && vehicleLicensePlate.length > 0
                        onClicked: {
                            console.log("Vehicle exit clicked for:", vehicleLicensePlate)
                            if (vehicleLicensePlate.length > 0) {
                                apiClient.vehicleExit(vehicleLicensePlate)
                            } else {
                                console.log("Cannot exit: license plate is empty")
                            }
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
                                                   orderTypeSequence: ["violation", "parking", "reservation"],
                                                   amount: fineAmount,
                                                   stackView: stackView,
                                                   onPaymentSucceeded: function(orderType, paidOrderId) {
                                                       tabBar.currentIndex = 3
                                                       loadViolations()
                                                       loadPaymentRecords()
                                                   }
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

    // Timer for delayed booking refresh after vehicle entry/exit
    Timer {
        id: bookingRefreshTimer
        interval: 1000  // 1 second delay
        repeat: false
        onTriggered: {
            loadBookings()
            // 再次延迟刷新以确保状态同步
            bookingRefreshTimer2.restart()
        }
    }
    
    Timer {
        id: bookingRefreshTimer2
        interval: 1000  // Another 1 second delay
        repeat: false
        onTriggered: {
            loadBookings()
        }
    }

    Component.onCompleted: {
        loadParkingStatus()
        loadUserVehicles()
        loadBookings()
        loadPaymentRecords()
        loadViolations()
    }

    function loadParkingStatus() {
        apiClient.getUserActiveParkingRecords(userId)
    }

    function loadUserVehicles() {
        apiClient.getUserVehicles()
    }

    function loadBookings() {
        // 先检查并更新超时的预订记录，然后再获取最新列表
        apiClient.checkAndUpdateExpiredBookings()
        // 延迟一下再获取预订列表，确保超时检查已完成
        Qt.callLater(function() {
            apiClient.getUserBookings(userId)
        })
    }

    function loadPaymentRecords() {
        apiClient.getUserPaymentRecords(1, 20)
    }

    function loadViolations() {
        // status参数已废弃，后端默认返回所有违规记录，这里传0作为占位
        apiClient.getUserViolations(userId, 0)
    }

    // 合并车辆列表和停车记录，更新 vehicleParkingStatusModel
    function updateVehicleParkingStatus() {
        vehicleParkingStatusModel.clear()
        
        // 如果车辆列表为空，直接返回
        if (userVehicleModel.count === 0) {
            console.log("updateVehicleParkingStatus: No vehicles in userVehicleModel")
            return
        }
        
        // 确保 activeParkingRecords 是数组
        if (!activeParkingRecords || !Array.isArray(activeParkingRecords)) {
            activeParkingRecords = []
        }
        
        // 创建停车记录映射表（按车牌号）
        var parkingMap = {}
        console.log("=== Building parking map ===")
        console.log("activeParkingRecords count:", activeParkingRecords.length)
        for (var i = 0; i < activeParkingRecords.length; i++) {
            var record = activeParkingRecords[i]
            if (!record || typeof record !== "object") {
                console.log("  Record", i, "is invalid:", record)
                continue
            }
            
            console.log("  Processing record", i, ":", JSON.stringify(record))
            
            var licensePlate = ""
            // 尝试多种方式获取车牌号（注意后端返回的是 LicensePlate，首字母大写）
            if (record.vehicle) {
                // 后端 Vehicle 模型的 JSON 标签是 LicensePlate（首字母大写）
                licensePlate = record.vehicle.LicensePlate || record.vehicle.licensePlate || record.vehicle.license_plate || ""
                console.log("    From record.vehicle:")
                console.log("      LicensePlate:", record.vehicle.LicensePlate)
                console.log("      licensePlate:", record.vehicle.licensePlate)
                console.log("      license_plate:", record.vehicle.license_plate)
                console.log("      Extracted:", licensePlate)
            }
            if (!licensePlate && record.license_plate) {
                licensePlate = record.license_plate
                console.log("    From record.license_plate:", licensePlate)
            }
            if (!licensePlate && record.licensePlate) {
                licensePlate = record.licensePlate
                console.log("    From record.licensePlate:", licensePlate)
            }
            if (!licensePlate && record.LicensePlate) {
                licensePlate = record.LicensePlate
                console.log("    From record.LicensePlate:", licensePlate)
            }
            
            // 如果还是没有，尝试遍历所有属性查找车牌号
            if (!licensePlate && record.vehicle) {
                for (var key in record.vehicle) {
                    if (key.toLowerCase().indexOf("license") >= 0 || key.toLowerCase().indexOf("plate") >= 0) {
                        var value = record.vehicle[key]
                        if (typeof value === "string" && value.length > 0) {
                            licensePlate = value
                            console.log("    Found license plate in vehicle key", key, ":", licensePlate)
                            break
                        }
                    }
                }
            }
            
            // 最后尝试在 record 本身查找
            if (!licensePlate) {
                for (var key in record) {
                    if ((key.toLowerCase().indexOf("license") >= 0 || key.toLowerCase().indexOf("plate") >= 0) && key !== "vehicle") {
                        var value = record[key]
                        if (typeof value === "string" && value.length > 0) {
                            licensePlate = value
                            console.log("    Found license plate in record key", key, ":", licensePlate)
                            break
                        }
                    }
                }
            }
            
            if (licensePlate.length > 0) {
                parkingMap[licensePlate] = record
                console.log("    Added to parkingMap:", licensePlate)
            } else {
                console.log("    WARNING: Could not extract license plate from record", i)
            }
        }
        console.log("parkingMap keys:", Object.keys(parkingMap))
        console.log("updateVehicleParkingStatus: Processing", userVehicleModel.count, "vehicles,", activeParkingRecords.length, "parking records")
        
        // 遍历所有车辆，创建状态项
        for (var j = 0; j < userVehicleModel.count; j++) {
            var vehicle = userVehicleModel.get(j)
            if (!vehicle) continue
            
            var licensePlate = vehicle.licensePlate || vehicle.license_plate || ""
            if (licensePlate.length === 0) {
                console.log("Warning: Vehicle at index", j, "has no license plate")
                continue
            }
            
            console.log("  Checking vehicle:", licensePlate)
            var parkingRecord = parkingMap[licensePlate]
            var isParking = (parkingRecord !== undefined && parkingRecord !== null)
            console.log("    Found parking record:", isParking, "for", licensePlate)
            
            // 确保所有必需的属性都有值
            var vehicleIdValue = vehicle.vehicleId || vehicle.vehicle_id || 0
            // 注意：不能使用 "model" 作为属性名，因为会与 QML 的 model 关键字冲突
            var statusItem = {
                vehicleId: vehicleIdValue,
                vehicle_id: vehicleIdValue,
                licensePlate: licensePlate,
                license_plate: licensePlate,
                brand: vehicle.brand || "",
                vehicleModel: vehicle.model || "",  // 改为 vehicleModel 避免冲突
                color: vehicle.color || "",
                isParking: isParking,  // 确保是布尔值
                recordId: parkingRecord ? (parkingRecord.record_id || parkingRecord.recordId || 0) : 0,
                lotName: parkingRecord && parkingRecord.lot ? (parkingRecord.lot.name || parkingRecord.lot.lot_name || "") : "",
                entryTime: parkingRecord ? (parkingRecord.entry_time || parkingRecord.entryTime || "") : "",
                spaceNumber: parkingRecord && parkingRecord.space ? (parkingRecord.space.space_number || parkingRecord.space.spaceNumber || "") : ""
            }
            
            console.log("Adding vehicle to status model:")
            console.log("  licensePlate:", licensePlate)
            console.log("  vehicleId:", vehicleIdValue)
            console.log("  isParking:", isParking)
            console.log("  Full statusItem keys:", Object.keys(statusItem))
            console.log("  statusItem.licensePlate:", statusItem.licensePlate)
            console.log("  statusItem.license_plate:", statusItem.license_plate)
            console.log("  statusItem.vehicleId:", statusItem.vehicleId)
            console.log("  statusItem.vehicle_id:", statusItem.vehicle_id)
            
            // 验证数据完整性
            if (!statusItem.licensePlate || statusItem.licensePlate.length === 0) {
                console.error("ERROR: licensePlate is empty in statusItem!")
            }
            if (!statusItem.vehicleId || statusItem.vehicleId === 0) {
                console.error("ERROR: vehicleId is invalid in statusItem!")
            }
            
            vehicleParkingStatusModel.append(statusItem)
            
            // 验证添加后的数据
            var lastIndex = vehicleParkingStatusModel.count - 1
            var addedItem = vehicleParkingStatusModel.get(lastIndex)
            console.log("  Verified added item at index", lastIndex, ":")
            console.log("    licensePlate:", addedItem ? addedItem.licensePlate : "null")
            console.log("    license_plate:", addedItem ? addedItem.license_plate : "null")
            console.log("    vehicleId:", addedItem ? addedItem.vehicleId : "null")
        }
        
        console.log("updateVehicleParkingStatus: Updated model with", vehicleParkingStatusModel.count, "items")
    }

    // 格式化停车时间
    function formatParkingTime(timeStr) {
        if (!timeStr) return ""
        try {
            var date = new Date(timeStr)
            if (isNaN(date.getTime())) return timeStr
            var year = date.getFullYear()
            var month = String(date.getMonth() + 1).padStart(2, '0')
            var day = String(date.getDate()).padStart(2, '0')
            var hour = String(date.getHours()).padStart(2, '0')
            var minute = String(date.getMinutes()).padStart(2, '0')
            return year + "-" + month + "-" + day + " " + hour + ":" + minute
        } catch (e) {
            return timeStr
        }
    }

    // 存储当前在场停车记录
    property var activeParkingRecords: []

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            var url = response.url || ""
            console.log("Request finished, URL:", url)

            // 统一错误处理（包括 HTTP 非 2xx 和网络层错误）
            var httpStatus = response.http_status !== undefined ? response.http_status : 200
            if (response.hasOwnProperty("error")) {
                var errorMsg = response.error || ""
                console.log("Error in UserMainPage:", errorMsg, "URL:", url, "HTTP Status:", httpStatus)
                
                // 对于停车状态，404 表示无在场记录，不当作错误
                if (url.indexOf("/active-parking") >= 0 && httpStatus === 404) {
                    // 404对于active-parking是正常的（无在场记录），不当作错误处理
                    console.log("No active parking records (404), this is normal")
                    activeParkingRecords = []
                    updateVehicleParkingStatus()
                    return
                }
                
                // 对于其他错误，只记录日志，不进行任何跳转操作
                // 特别是401/403错误，不应该导致跳转到登录页
                if (httpStatus === 401 || httpStatus === 403) {
                    console.log("Authentication error detected, but not navigating to login page")
                    // 设置为无在场记录状态，避免一直停留在"加载中..."
                    if (url.indexOf("/active-parking") >= 0) {
                        activeParkingRecords = []
                        updateVehicleParkingStatus()
                    }
                    return
                }
                
                // 其他错误：对于停车状态也回落到"暂无车辆"，避免一直"加载中..."
                if (url.indexOf("/active-parking") >= 0) {
                    activeParkingRecords = []
                    updateVehicleParkingStatus()
                }
                return
            }

            // Handle active parking records response
            if (url.indexOf("/active-parking") >= 0) {
                console.log("Active parking records response:", JSON.stringify(response))

                // Handle parking records data
                // 后端直接返回数组，也可能包装在data字段中
                var data = []
                if (Array.isArray(response)) {
                    // 如果response本身就是数组
                    data = response
                } else if (response.data && Array.isArray(response.data)) {
                    // 如果response.data是数组
                    data = response.data
                } else if (Array.isArray(response)) {
                    data = response
                }
                
                // 保存停车记录
                activeParkingRecords = data
                console.log("=== Active parking records received ===")
                console.log("Count:", activeParkingRecords.length, "records")
                if (activeParkingRecords.length > 0) {
                    console.log("First record (full):", JSON.stringify(activeParkingRecords[0], null, 2))
                    var firstRecord = activeParkingRecords[0]
                    if (firstRecord.vehicle) {
                        console.log("  First record.vehicle:", JSON.stringify(firstRecord.vehicle))
                        console.log("  First record.vehicle.license_plate:", firstRecord.vehicle.license_plate)
                        console.log("  First record.vehicle.licensePlate:", firstRecord.vehicle.licensePlate)
                    }
                } else {
                    console.log("No active parking records")
                }
                
                // 更新车辆停车状态模型（只有在车辆列表已加载时才更新）
                if (userVehicleModel.count > 0) {
                    console.log("Updating vehicle parking status with", userVehicleModel.count, "vehicles")
                    updateVehicleParkingStatus()
                } else {
                    console.log("Parking records received but vehicles not loaded yet, will update when vehicles are loaded")
                }
                return
            }

            // Handle vehicle exit response
            if (url.indexOf("/api/parking/exit") >= 0) {
                if (response.hasOwnProperty("error")) {
                    console.log("Vehicle exit error:", response.error)
                    return
                }
                // Vehicle exit successful, refresh parking status and bookings
                // Reload parking status
                loadParkingStatus()
                // 车辆离场后，如果关联了预订，预订状态会更新为已完成，需要刷新预订列表
                // 延迟刷新以确保后端状态已更新
                bookingRefreshTimer.restart()
                return
            }

            // Handle add/delete vehicle response (POST/DELETE /api/v1/vehicles)
            if (url.indexOf("/api/v1/vehicles") >= 0) {
                var method = response.method || ""
                // Check if this is a POST (add) or DELETE (remove) request
                // POST: /api/v1/vehicles (no ID in URL, returns success message, not array)
                // DELETE: /api/v1/vehicles/{id} (has ID in URL, returns success message)
                // GET: /api/v1/vehicles (returns array in data field, handled by onUserVehiclesReceived)
                var isDeleteRequest = url.match(/\/api\/v1\/vehicles\/\d+$/) !== null
                var hasDataArray = response.hasOwnProperty("data") && Array.isArray(response.data)
                var isPostRequest = (method === "POST" || (!isDeleteRequest && !hasDataArray && httpStatus >= 200 && httpStatus < 300))
                var isDeleteMethod = (method === "DELETE" || isDeleteRequest)
                
                if (isPostRequest || isDeleteMethod) {
                    // Add or delete vehicle successful, refresh the list
                    if (httpStatus >= 200 && httpStatus < 300 && !response.hasOwnProperty("error")) {
                        console.log("Vehicle " + (isPostRequest ? "added" : "deleted") + " successfully, refreshing list")
                        // Clear form fields only for POST (add)
                        if (isPostRequest) {
                            licensePlateField.text = ""
                            brandField.text = ""
                            modelField.text = ""
                            colorField.text = ""
                        }
                        // Refresh vehicle list after a short delay to ensure backend has updated
                        Qt.callLater(function() {
                            loadUserVehicles()
                        })
                        return
                    }
                }
                // GET requests are handled by onUserVehiclesReceived
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
            
            // Handle parking entry response - refresh parking status and bookings
            if (url.indexOf("/api/parking/entry") >= 0) {
                if (!response.hasOwnProperty("error")) {
                    console.log("=== Parking entry success ===")
                    console.log("Response:", JSON.stringify(response))
                    // 立即刷新停车状态
                    console.log("Reloading parking status...")
                    loadParkingStatus()
                    // 车辆入场后，如果使用了预订车位，预订状态会更新为使用中，需要刷新预订列表
                    // 实时刷新预订列表
                    if (userId > 0) {
                        apiClient.getUserBookings(userId)
                    }
                    // 延迟刷新以确保后端状态已更新
                    bookingRefreshTimer.restart()
                } else {
                    console.log("Parking entry failed:", response.error)
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

        function onUserVehiclesReceived(vehicles) {
            userVehicleModel.clear()
            if (!vehicles || !Array.isArray(vehicles)) {
                console.log("onUserVehiclesReceived: vehicles is not array")
                // 即使没有车辆，也要更新状态（清空列表）
                updateVehicleParkingStatus()
                return
            }
            console.log("onUserVehiclesReceived: received", vehicles.length, "vehicles")
            for (var i = 0; i < vehicles.length; i++) {
                var v = vehicles[i]
                if (v && typeof v === "object") {
                    var vid = v.vehicle_id !== undefined ? v.vehicle_id :
                              (v.vehicleId !== undefined ? v.vehicleId :
                              (v.VehicleID !== undefined ? v.VehicleID : 0))
                    var plate = v.license_plate !== undefined ? v.license_plate :
                                (v.licensePlate !== undefined ? v.licensePlate :
                                (v.LicensePlate !== undefined ? v.LicensePlate : ""))
                    if (vid > 0 && plate.length > 0) {
                        userVehicleModel.append({
                            vehicleId: vid,
                            vehicle_id: vid,
                            licensePlate: plate,
                            license_plate: plate,
                            brand: v.brand || v.Brand || "",
                            model: v.model || v.Model || "",
                            color: v.color || v.Color || ""
                        })
                        console.log("Added vehicle to model:", plate, "ID:", vid)
                    } else {
                        console.log("Skipped invalid vehicle:", JSON.stringify(v))
                    }
                }
            }
            console.log("userVehicleModel now has", userVehicleModel.count, "vehicles")
            // 更新车辆停车状态模型
            updateVehicleParkingStatus()
        }

        function onActiveParkingRecordsReceived(records) {
            // This is for parking records, not bookings
            // Parking records are handled in onRequestFinished
        }

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

