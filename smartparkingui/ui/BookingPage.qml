import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    id: bookingPage
    title: "车位预订"

    property int userId: 0
    property int selectedLotId: 0
    property int selectedVehicleId: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "新建预订"
            font.pixelSize: 24
            font.bold: true
        }

        // Parking lot selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "选择停车场"
                font.pixelSize: 14
            }

            ComboBox {
                id: lotComboBox
                Layout.fillWidth: true
                model: parkingLotModel
                textRole: "name"
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < model.count) {
                        var item = model.get(currentIndex)
                        // 后端字段多为 snake_case：lot_id
                        var lotIdValue = item.lot_id !== undefined ? item.lot_id :
                                         (item.lotId !== undefined ? item.lotId : 0)
                        selectedLotId = lotIdValue
                        if (selectedLotId > 0) {
                            apiClient.getParkingSpaces(selectedLotId)
                        }
                    } else {
                        selectedLotId = 0
                    }
                }
            }
        }

        // Vehicle selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "选择车辆车牌号"
                font.pixelSize: 14
            }

            ComboBox {
                id: vehicleComboBox
                Layout.fillWidth: true
                model: vehicleModel
                textRole: "licensePlate"
                onCurrentIndexChanged: {
                    if (currentIndex >= 0 && currentIndex < model.count) {
                        var v = model.get(currentIndex)
                        var vehicleIdValue = v.vehicle_id !== undefined ? v.vehicle_id :
                                             (v.vehicleId !== undefined ? v.vehicleId : 0)
                        selectedVehicleId = vehicleIdValue
                        console.log("Selected vehicle ID:", vehicleIdValue, "License:", v.licensePlate || v.license_plate)
                    } else {
                        selectedVehicleId = 0
                    }
                }
            }

            // 当无车辆可选时给出明显提示
            Text {
                visible: vehicleModel.count === 0
                text: "无可用车辆，请在注册时添加车辆或联系管理员添加车辆后再预订。"
                font.pixelSize: 12
                color: "red"
                wrapMode: Text.Wrap
            }
        }

        // Space type selection
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "选择车位类型"
                font.pixelSize: 14
            }

            ComboBox {
                id: spaceTypeComboBox
                Layout.fillWidth: true
                model: ["普通", "充电桩"]
                currentIndex: 0
            }
        }

        // Start time (date/time editors via SpinBox)
        RowLayout {
            Layout.fillWidth: true
            Text { text: "开始时间:" }
            SpinBox { id: startYear; from: 2020; to: 2100; value: new Date().getFullYear() }
            SpinBox { id: startMonth; from: 1; to: 12; value: new Date().getMonth() + 1 }
            SpinBox { id: startDay; from: 1; to: 31; value: new Date().getDate() }
            SpinBox { id: startHour; from: 0; to: 23; value: 8 }
            SpinBox { id: startMinute; from: 0; to: 59; value: 0 }
        }

        // End time (date/time editors via SpinBox)
        RowLayout {
            Layout.fillWidth: true
            Text { text: "结束时间:" }
            SpinBox { id: endYear; from: 2020; to: 2100; value: new Date().getFullYear() }
            SpinBox { id: endMonth; from: 1; to: 12; value: new Date().getMonth() + 1 }
            SpinBox { id: endDay; from: 1; to: 31; value: new Date().getDate() }
            SpinBox { id: endHour; from: 0; to: 23; value: 10 }
            SpinBox { id: endMinute; from: 0; to: 59; value: 0 }
        }

        // Space visualization button
        Button {
            Layout.fillWidth: true
            text: "查看车位可视化"
            onClicked: {
                var lotIdToUse = selectedLotId

                // 如果还未显式选择，但已有停车场列表，则默认使用当前/第一个
                if (lotIdToUse <= 0 && parkingLotModel.count > 0) {
                    var useIndex = lotComboBox.currentIndex >= 0 ? lotComboBox.currentIndex : 0
                    var item = parkingLotModel.get(useIndex)
                    var autoLotId = item.lot_id !== undefined ? item.lot_id :
                                    (item.lotId !== undefined ? item.lotId : 0)
                    lotIdToUse = autoLotId
                    selectedLotId = autoLotId
                }

                if (lotIdToUse <= 0) {
                    console.log("No parking lot available, cannot open visualization")
                    return
                }
                if (stackView) {
                    // 通过 URL 创建页面，避免依赖外部 Component id
                    stackView.push(Qt.resolvedUrl("ParkingVisualizationPage.qml"), {
                                       lotId: lotIdToUse,
                                       stackView: stackView
                                   })
                } else {
                    console.log("stackView is null, cannot push ParkingVisualizationPage")
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Submit button
        Button {
            Layout.fillWidth: true
            text: "提交预订"
            enabled: selectedLotId > 0 && selectedVehicleId > 0
            onClicked: {
                var spaceType = spaceTypeComboBox.currentText || "普通"
                apiClient.createBooking(
                            userId,
                            selectedVehicleId,
                            selectedLotId,
                            formatDateTime(startYear, startMonth, startDay, startHour, startMinute),
                            formatDateTime(endYear, endMonth, endDay, endHour, endMinute),
                            spaceType)
            }
        }

        Button {
            Layout.fillWidth: true
            text: "取消"
            onClicked: {
                console.log("Cancel button clicked, stackView:", stackView)
                if (stackView) {
                    console.log("Popping BookingPage")
                    stackView.pop()
                } else {
                    console.log("stackView is null, cannot pop BookingPage")
                }
            }
        }
    }

    ListModel {
        id: parkingLotModel
    }

    ListModel {
        id: vehicleModel
    }

    Component.onCompleted: {
        apiClient.getParkingLots()
        // 优先使用后端接口获取车辆列表，authManager.userInfo 作为兜底
        apiClient.getUserVehicles()
        loadUserVehicles()
    }

    onVisibleChanged: {
        if (visible) {
            loadUserVehicles()
        }
    }

    function cloneObject(obj) {
        if (!obj)
            return null
        try {
            return JSON.parse(JSON.stringify(obj))
        } catch (err) {
            console.log("cloneObject failed:", err)
            return obj
        }
    }

    function sanitizeVehicle(veh) {
        if (!veh || typeof veh !== "object")
            return null
        var vehicleId = veh.vehicle_id !== undefined ? veh.vehicle_id :
                        (veh.vehicleId !== undefined ? veh.vehicleId :
                        (veh.VehicleID !== undefined ? veh.VehicleID : 0))
        var licensePlate = veh.license_plate !== undefined ? veh.license_plate :
                           (veh.licensePlate !== undefined ? veh.licensePlate :
                           (veh.LicensePlate !== undefined ? veh.LicensePlate : ""))
        if (vehicleId <= 0 || licensePlate.length === 0)
            return null
        return {
            vehicleId: vehicleId,
            vehicle_id: vehicleId,
            licensePlate: licensePlate,
            license_plate: licensePlate
        }
    }

    function sanitizeLot(lot) {
        if (!lot || typeof lot !== "object")
            return null
        var lotId = lot.lot_id !== undefined ? lot.lot_id :
                    (lot.lotId !== undefined ? lot.lotId :
                    (lot.LotID !== undefined ? lot.LotID : 0))
        return {
            lotId: lotId,
            lot_id: lotId,
            name: lot.name || lot.Name || "",
            address: lot.address || lot.Address || "",
            hourlyRate: lot.hourly_rate !== undefined ? lot.hourly_rate :
                        (lot.hourlyRate !== undefined ? lot.hourlyRate : 0),
            totalLevels: lot.total_levels !== undefined ? lot.total_levels :
                         (lot.totalLevels !== undefined ? lot.totalLevels : 1),
            totalSpaces: lot.total_spaces !== undefined ? lot.total_spaces :
                         (lot.totalSpaces !== undefined ? lot.totalSpaces : 0)
        }
    }

    // 将年月日时分 SpinBox 转换为 RFC3339 字符串
    function formatDateTime(y, m, d, h, min) {
        function pad2(n) { return n < 10 ? "0" + n : "" + n }
        var year = y.value
        var month = pad2(m.value)
        var day = pad2(d.value)
        var hour = pad2(h.value)
        var minute = pad2(min.value)
        var second = "00"
        return year + "-" + month + "-" + day + "T" + hour + ":" + minute + ":" + second + "Z"
    }

    function loadUserVehicles() {
        vehicleModel.clear()
        var info = cloneObject(authManager.userInfo)
        if (info)
            console.log("Loading vehicles from userInfo:", JSON.stringify(info))

        var vehicles = null
        if (info) {
            if (info.vehicles !== undefined) {
                vehicles = info.vehicles
            } else if (info.Vehicles !== undefined) {
                vehicles = info.Vehicles
            }
        }

        if (vehicles && Array.isArray(vehicles)) {
            for (var i = 0; i < vehicles.length; i++) {
                var clean = sanitizeVehicle(vehicles[i])
                if (clean)
                    vehicleModel.append(clean)
            }
        } else if (vehicles && typeof vehicles === "object") {
            for (var key in vehicles) {
                if (vehicles.hasOwnProperty(key)) {
                    var cleanObj = sanitizeVehicle(vehicles[key])
                    if (cleanObj)
                        vehicleModel.append(cleanObj)
                }
            }
        }

        console.log("Loaded vehicles count:", vehicleModel.count)
        if (vehicleModel.count === 0) {
            console.log("Warning: No vehicles found for user:", JSON.stringify(info))
        }
    }

    Connections {
        target: authManager
        function onLoginStatusChanged() {
            loadUserVehicles()
        }
    }

    Connections {
        target: apiClient

        function onParkingLotsReceived(lots) {
            parkingLotModel.clear()
            for (var i = 0; i < lots.length; i++) {
                var clean = sanitizeLot(lots[i])
                if (clean) {
                    parkingLotModel.append(clean)
                }
            }

            // 默认选中第一个停车场，便于后续直接查看可视化
            if (parkingLotModel.count > 0) {
                lotComboBox.currentIndex = 0
            } else {
                selectedLotId = 0
            }
        }

        // 来自 /api/v1/vehicles 的车辆列表
        function onUserVehiclesReceived(vehicles) {
            if (!vehicles || !Array.isArray(vehicles)) {
                return
            }
            vehicleModel.clear()
            console.log("Received vehicles from /api/v1/vehicles:", JSON.stringify(vehicles))
            for (var i = 0; i < vehicles.length; i++) {
                var clean = sanitizeVehicle(vehicles[i])
                if (clean) {
                    vehicleModel.append(clean)
                }
            }
            console.log("VehicleModel count after API:", vehicleModel.count)
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            if (response.hasOwnProperty("code") && response.code === 0) {
                // Booking created successfully
                if (stackView) {
                    stackView.pop()
                }
            }
        }
    }
}

