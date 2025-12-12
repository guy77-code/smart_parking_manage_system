import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    property var parentWindow: null  // 用于Dialog的parent
    id: parkingEntryPage
    title: "车辆入场"

    property int userId: 0
    property int selectedLotId: 0
    property int selectedVehicleId: 0
    property string selectedLicensePlate: ""
    property int preSelectedVehicleId: 0
    property string preSelectedLicensePlate: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "车辆入场"
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
                        var lotIdValue = item.lot_id !== undefined ? item.lot_id :
                                         (item.lotId !== undefined ? item.lotId : 0)
                        selectedLotId = lotIdValue
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
                        selectedLicensePlate = v.licensePlate || v.license_plate || ""
                        console.log("Selected vehicle ID:", vehicleIdValue, "License:", selectedLicensePlate)
                    } else {
                        selectedVehicleId = 0
                        selectedLicensePlate = ""
                    }
                }
            }

            Text {
                visible: vehicleModel.count === 0
                text: "无可用车辆，请在注册时添加车辆或联系管理员添加车辆。"
                font.pixelSize: 12
                color: "red"
                wrapMode: Text.Wrap
            }
        }

        // Space type selection (optional)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "车位类型（可选）"
                font.pixelSize: 14
            }

            ComboBox {
                id: spaceTypeComboBox
                Layout.fillWidth: true
                model: ["普通", "充电桩", "残疾人", "VIP"]
                currentIndex: 0
            }
        }

        Item { Layout.fillHeight: true }

        // Submit button
        Button {
            Layout.fillWidth: true
            text: "确认入场"
            enabled: selectedLotId > 0 && selectedVehicleId > 0 && selectedLicensePlate.length > 0
            onClicked: {
                // 先检查是否有有效预订（传递车牌号和停车场ID）
                console.log("Checking valid reservation for:", selectedLicensePlate, "lotId:", selectedLotId)
                apiClient.checkValidReservation(selectedLicensePlate, selectedLotId)
            }
        }

        Button {
            Layout.fillWidth: true
            text: "取消"
            onClicked: {
                if (stackView) {
                    stackView.pop()
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
        // 如果有预选车辆，设置选中
        if (preSelectedVehicleId > 0 && preSelectedLicensePlate.length > 0) {
            Qt.callLater(function() {
                selectPreSelectedVehicle()
            })
        }
    }
    
    function selectPreSelectedVehicle() {
        for (var i = 0; i < vehicleModel.count; i++) {
            var v = vehicleModel.get(i)
            var vid = v.vehicleId || v.vehicle_id || 0
            var plate = v.licensePlate || v.license_plate || ""
            if (vid === preSelectedVehicleId && plate === preSelectedLicensePlate) {
                vehicleComboBox.currentIndex = i
                break
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            loadUserVehicles()
            // 如果有预选车辆，重新设置选中
            if (preSelectedVehicleId > 0 && preSelectedLicensePlate.length > 0) {
                Qt.callLater(function() {
                    selectPreSelectedVehicle()
                })
            }
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
            console.log("Warning: No vehicles found in userInfo:", JSON.stringify(info))
        }
    }

    // 格式化时间字符串（RFC3339格式转换为可读格式）
    function formatDateTime(timeStr) {
        if (!timeStr) return ""
        try {
            // 解析RFC3339格式时间（如 "2025-12-06T19:00:00+08:00"）
            var date = new Date(timeStr)
            if (isNaN(date.getTime())) {
                // 如果解析失败，尝试其他格式或直接返回原字符串
                return timeStr
            }
            // 格式化为本地时间字符串：YYYY-MM-DD HH:mm:ss
            var year = date.getFullYear()
            var month = String(date.getMonth() + 1).padStart(2, '0')
            var day = String(date.getDate()).padStart(2, '0')
            var hour = String(date.getHours()).padStart(2, '0')
            var minute = String(date.getMinutes()).padStart(2, '0')
            var second = String(date.getSeconds()).padStart(2, '0')
            return year + "-" + month + "-" + day + " " + hour + ":" + minute + ":" + second
        } catch (e) {
            console.log("Error formatting datetime:", e, "timeStr:", timeStr)
            return timeStr
        }
    }

    // 预订信息提示框
    Dialog {
        id: reservationInfoDialog
        modal: true
        title: "预约使用成功"
        standardButtons: Dialog.Ok
        
        property var reservationInfo: null
        
        width: 450
        height: 300
        
        contentItem: ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Text {
                id: reservationInfoText
                Layout.fillWidth: true
                Layout.fillHeight: true
                font.pixelSize: 14
                wrapMode: Text.Wrap
                text: "加载中..."
            }
        }
        
        onAccepted: {
            // 用户点击确定后，执行入场逻辑
            console.log("=== Dialog onAccepted triggered ===")
            console.log("User confirmed reservation info, proceeding with entry")
            console.log("selectedLicensePlate:", selectedLicensePlate)
            console.log("selectedLotId:", selectedLotId)
            var spaceType = spaceTypeComboBox.currentText
            console.log("spaceType:", spaceType)
            console.log("Calling vehicleEntry with:", selectedLicensePlate, spaceType, selectedLotId)
            
            if (!selectedLicensePlate || selectedLicensePlate.length === 0) {
                console.error("Error: selectedLicensePlate is empty, cannot proceed with entry")
                return
            }
            
            if (selectedLotId <= 0) {
                console.error("Error: selectedLotId is invalid:", selectedLotId)
                return
            }
            
            apiClient.vehicleEntry(selectedLicensePlate, spaceType, selectedLotId)
            console.log("vehicleEntry call completed")
        }
    }

    Connections {
        target: apiClient

        function onValidReservationChecked(response) {
            console.log("=== onValidReservationChecked called ===")
            console.log("Full response:", JSON.stringify(response, null, 2))
            
            // 检查响应是否被包装在 data 字段中
            var actualResponse = response
            if (response.data && typeof response.data === 'object') {
                console.log("Response wrapped in data field, unwrapping...")
                actualResponse = response.data
            }
            
            var hasReservation = actualResponse.has_reservation || false
            var httpStatus = response.http_status || actualResponse.http_status || 200
            
            console.log("has_reservation:", hasReservation, "http_status:", httpStatus)
            
            // 如果接口返回错误（如404），也当作没有预订处理
            if (httpStatus >= 400) {
                console.log("Check reservation API returned error, treating as no reservation")
                hasReservation = false
            }
            
            if (hasReservation) {
                // 有有效预订，显示信息提示框
                console.log("Has valid reservation, showing info dialog")
                var reservation = actualResponse.reservation || {}
                var space = actualResponse.space || {}
                var lot = actualResponse.lot || {}
                var vehicle = reservation.vehicle || reservation.Vehicle || {}
                
                console.log("Reservation:", JSON.stringify(reservation))
                console.log("Space:", JSON.stringify(space))
                console.log("Lot:", JSON.stringify(lot))
                console.log("Vehicle:", JSON.stringify(vehicle))
                
                reservationInfoDialog.reservationInfo = actualResponse
                
                // 获取车牌号（优先使用预订中的车辆信息，否则使用用户选择的车牌号）
                var licensePlate = selectedLicensePlate || 
                                  vehicle.license_plate || 
                                  vehicle.licensePlate || 
                                  vehicle.LicensePlate || 
                                  ""
                
                // 格式化预订信息显示（按照用户要求：车牌号、停车场、预约停放时间、停车位序号、停车位类型）
                var details = "预约使用成功\n\n"
                details += "车牌号: " + licensePlate + "\n"
                details += "停车场: " + (lot.name || "") + "\n"
                
                // 预约停放时间
                if (reservation.start_time) {
                    details += "预约开始时间: " + formatDateTime(reservation.start_time) + "\n"
                } else if (reservation.startTime) {
                    details += "预约开始时间: " + formatDateTime(reservation.startTime) + "\n"
                }
                if (reservation.end_time) {
                    details += "预约结束时间: " + formatDateTime(reservation.end_time) + "\n"
                } else if (reservation.endTime) {
                    details += "预约结束时间: " + formatDateTime(reservation.endTime) + "\n"
                }
                
                details += "停车位序号: " + (space.space_number || space.spaceNumber || "") + "\n"
                details += "停车位类型: " + (space.space_type || space.spaceType || "") + "\n"
                
                console.log("Reservation details:", details)
                reservationInfoText.text = details
                
                // 显示提示框，用户点击确定后自动执行入场
                reservationInfoDialog.open()
            } else {
                // 没有有效预订，直接执行停车逻辑
                console.log("No valid reservation, proceeding with direct entry")
                var spaceType = spaceTypeComboBox.currentText
                apiClient.vehicleEntry(selectedLicensePlate, spaceType, selectedLotId)
            }
        }
        
        function onRequestError(error) {
            // 如果检查预订接口出错，也当作没有预订处理，直接执行入场
            console.log("Request error in ParkingEntryPage:", error)
            // 注意：这里不能直接判断是哪个接口出错，所以不在这里处理
            // 而是在 onValidReservationChecked 中处理
        }

        function onParkingLotsReceived(lots) {
            parkingLotModel.clear()
            for (var i = 0; i < lots.length; i++) {
                var clean = sanitizeLot(lots[i])
                if (clean) {
                    parkingLotModel.append(clean)
                }
            }

            if (parkingLotModel.count > 0) {
                lotComboBox.currentIndex = 0
            } else {
                selectedLotId = 0
            }
        }

        function onRequestFinished(response) {
            console.log("=== onRequestFinished in ParkingEntryPage ===")
            console.log("Response:", JSON.stringify(response))
            
            var url = response.url || ""
            var httpStatus = response.http_status || 200
            
            console.log("URL:", url, "HTTP Status:", httpStatus)
            
            if (url.indexOf("/api/parking/entry") >= 0) {
                console.log("Vehicle entry response received")
                if (response.hasOwnProperty("error")) {
                    console.error("Vehicle entry error:", response.error)
                    return
                }
                
                if (httpStatus >= 200 && httpStatus < 300) {
                    console.log("Vehicle entry successful, popping page")
                    // 入场成功，刷新预订列表并返回上一页
                    // 通知父页面刷新预订列表
                    if (stackView) {
                        stackView.pop()
                    }
                } else {
                    console.error("Vehicle entry failed with HTTP status:", httpStatus)
                }
            }
        }

        // 来自 /api/v1/vehicles 的车辆列表
        function onUserVehiclesReceived(vehicles) {
            if (!vehicles || !Array.isArray(vehicles)) {
                return
            }
            vehicleModel.clear()
            console.log("Received vehicles from /api/v1/vehicles (ParkingEntryPage):", JSON.stringify(vehicles))
            for (var i = 0; i < vehicles.length; i++) {
                var clean = sanitizeVehicle(vehicles[i])
                if (clean) {
                    vehicleModel.append(clean)
                }
            }
            console.log("VehicleModel count after API (ParkingEntryPage):", vehicleModel.count)
        }
    }

    Connections {
        target: authManager
        function onLoginStatusChanged() {
            loadUserVehicles()
        }
    }
}

