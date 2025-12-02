import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: parkingVisualizationPage
    title: "车位可视化"

    property var stackView: null
    property int lotId: 0
    property int currentLevel: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // 返回按钮
        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "返回"
                onClicked: {
                    if (stackView) {
                        stackView.pop()
                    } else {
                        console.log("stackView is null, cannot pop ParkingVisualizationPage")
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        // Level selector
        RowLayout {
            Layout.fillWidth: true
            Text { text: "楼层:" }
            SpinBox {
                id: levelSpinBox
                from: 1
                to: 10
                value: currentLevel
                onValueChanged: currentLevel = value
            }
            Item { Layout.fillWidth: true }
        }

        // Legend
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                width: 30
                height: 30
                color: "green"
                border.color: "black"
            }
            Text { text: "可用" }
            Rectangle {
                width: 30
                height: 30
                color: "red"
                border.color: "black"
            }
            Text { text: "占用" }
            Rectangle {
                width: 30
                height: 30
                color: "blue"
                border.color: "black"
            }
            Text { text: "已预订" }
            Rectangle {
                width: 30
                height: 30
                color: "yellow"
                border.color: "black"
            }
            Text { text: "禁用" }
        }

        // Parking spaces grid
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                id: spaceGrid
                columns: 10
                width: parent.width

                Repeater {
                    model: spaceModel
                    delegate: Rectangle {
                        width: 80
                        height: 80
                        color: getSpaceColor(model.status, model.isOccupied, model.isReserved)
                        border.color: "black"
                        border.width: 2
                        radius: 5

                        ColumnLayout {
                            anchors.centerIn: parent
                            Text {
                                text: model.spaceNumber || ""
                                font.pixelSize: 12
                                font.bold: true
                            }
                            Text {
                                text: model.spaceType || ""
                                font.pixelSize: 10
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                // Show space details or select for booking
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: spaceModel
    }

    function getSpaceColor(status, isOccupied, isReserved) {
        if (status === 0) return "yellow"  // Disabled
        if (isOccupied === 1) return "red"  // Occupied
        if (isReserved === 1) return "blue"  // Reserved
        return "green"  // Available
    }

    Component.onCompleted: {
        if (lotId > 0) {
            apiClient.getParkingSpaces(lotId)
        }
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            var spaces = response.data || response
            if (Array.isArray(spaces)) {
                spaceModel.clear()
                for (var i = 0; i < spaces.length; i++) {
                    var space = spaces[i]
                    if (space.level === currentLevel) {
                        spaceModel.append(space)
                    }
                }
            }
        }
    }
}

