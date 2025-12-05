import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    property var stackView: null
    id: parkingEntryPage
    title: "车辆入场"

    property int userId: 0
    property int selectedLotId: 0
    property int selectedVehicleId: 0
    property string selectedLicensePlate: ""

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
                var spaceType = spaceTypeComboBox.currentText
                apiClient.vehicleEntry(selectedLicensePlate, spaceType)
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

            if (parkingLotModel.count > 0) {
                lotComboBox.currentIndex = 0
            } else {
                selectedLotId = 0
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            var url = response.url || ""
            if (url.indexOf("/api/parking/entry") >= 0) {
                // 入场成功，返回上一页
                if (stackView) {
                    stackView.pop()
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

