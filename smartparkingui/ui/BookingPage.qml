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

        // Start time
        RowLayout {
            Layout.fillWidth: true
            Text { text: "开始时间:" }
            TextField {
                id: startTimeField
                Layout.fillWidth: true
                placeholderText: "2025-01-02T10:00:00Z"
            }
        }

        // End time
        RowLayout {
            Layout.fillWidth: true
            Text { text: "结束时间:" }
            TextField {
                id: endTimeField
                Layout.fillWidth: true
                placeholderText: "2025-01-02T12:00:00Z"
            }
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
            enabled: selectedLotId > 0 && selectedVehicleId > 0 && startTimeField.text.length > 0 && endTimeField.text.length > 0
            onClicked: {
                apiClient.createBooking(userId, selectedVehicleId, selectedLotId, startTimeField.text, endTimeField.text)
            }
        }

        Button {
            Layout.fillWidth: true
            text: "取消"
            onClicked: {
                if (stackView) {
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

        // 从登录用户信息中尝试加载车辆列表（如果后端返回了 vehicles 字段）
        vehicleModel.clear()
        var info = authManager.userInfo
        if (info && info.vehicles && Array.isArray(info.vehicles)) {
            for (var i = 0; i < info.vehicles.length; i++) {
                var veh = info.vehicles[i]
                if (veh) {
                    // 统一字段名，便于 ComboBox 使用
                    vehicleModel.append({
                        vehicleId: veh.vehicle_id !== undefined ? veh.vehicle_id : (veh.vehicleId || 0),
                        licensePlate: veh.license_plate !== undefined ? veh.license_plate : (veh.licensePlate || "")
                    })
                }
            }
        }
    }

    Connections {
        target: apiClient

        function onParkingLotsReceived(lots) {
            parkingLotModel.clear()
            for (var i = 0; i < lots.length; i++) {
                parkingLotModel.append(lots[i])
            }

            // 默认选中第一个停车场，便于后续直接查看可视化
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

            if (response.hasOwnProperty("code") && response.code === 0) {
                // Booking created successfully
                if (stackView) {
                    stackView.pop()
                }
            }
        }
    }
}

