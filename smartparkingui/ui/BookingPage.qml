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
        ComboBox {
            id: lotComboBox
            Layout.fillWidth: true
            model: parkingLotModel
            textRole: "name"
            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    selectedLotId = model.get(currentIndex).lotId
                    apiClient.getParkingSpaces(selectedLotId)
                }
            }
        }

        // Vehicle selection
        ComboBox {
            id: vehicleComboBox
            Layout.fillWidth: true
            model: vehicleModel
            textRole: "licensePlate"
            onCurrentIndexChanged: {
                if (currentIndex >= 0) {
                    selectedVehicleId = model.get(currentIndex).vehicleId
                }
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
                stackView.push(parkingVisualizationPage, { lotId: selectedLotId })
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
                stackView.pop()
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
        // Load user vehicles
        // apiClient.getUserVehicles(userId)
    }

    Connections {
        target: apiClient

        function onParkingLotsReceived(lots) {
            parkingLotModel.clear()
            for (var i = 0; i < lots.length; i++) {
                parkingLotModel.append(lots[i])
            }
        }

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            if (response.hasOwnProperty("code") && response.code === 0) {
                // Booking created successfully
                stackView.pop()
            }
        }
    }
}

