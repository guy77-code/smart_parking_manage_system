import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: adminMainPage
    title: "管理员中心"

    property var stackView: null
    property int userId: 0
    property string userType: ""
    signal logout()

    TabBar {
        id: tabBar
        width: parent.width

        TabButton { text: "停车场管理"; visible: userType === "system_admin" }
        TabButton { text: "车位管理"; visible: userType === "lot_admin" }
        TabButton { text: "数据分析" }
        TabButton { text: "违规分析"; visible: userType === "system_admin" }
    }

    StackLayout {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: tabBar.currentIndex

        // Parking Lot Management (System Admin)
        ScrollView {
            visible: userType === "system_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    RowLayout {
                    Text {
                        text: "停车场管理"
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "添加停车场"
                        onClicked: {
                            // Show add parking lot dialog
                        }
                    }
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    model: parkingLotModel
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 100
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            ColumnLayout {
                                Text { text: model.name || "" }
                                Text { text: model.address || "" }
                                Text { text: "费率: ¥" + (model.hourlyRate || 0) + "/小时" }
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "查看详情"
                                onClicked: {
                                    stackView.push(adminDataPage, { lotId: model.lotId })
                                }
                            }
                        }
                    }
                    }
                }
            }
        }

        // Space Management (Lot Admin)
        ScrollView {
            visible: userType === "lot_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "车位管理"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    ListView {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 500
                        model: spaceModel
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 80
                            border.color: "gray"
                            border.width: 1
                            radius: 5

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                Text { text: "车位编号: " + (model.spaceNumber || "") }
                                Text { text: "类型: " + (model.spaceType || "") }
                                Text { text: "状态: " + (model.isOccupied === 1 ? "占用" : "空闲") }
                                Item { Layout.fillWidth: true }
                                Button {
                                    text: "修改状态"
                                    onClicked: {
                                        // Show status update dialog
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Data Analysis
        ScrollView {
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "数据分析"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    RowLayout {
                        Text { text: "开始时间:" }
                        TextField {
                            id: startTimeField
                            placeholderText: "2025-01-01T00:00:00Z"
                        }
                        Text { text: "结束时间:" }
                        TextField {
                            id: endTimeField
                            placeholderText: "2025-01-31T23:59:59Z"
                        }
                        Button {
                            text: "查询"
                            onClicked: {
                                apiClient.getOccupancyAnalysis(startTimeField.text, endTimeField.text)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        Text {
                            anchors.centerIn: parent
                            text: "数据分析结果将显示在这里"
                            color: "gray"
                        }
                    }
                }
            }
        }

        // Violation Analysis (System Admin)
        ScrollView {
            visible: userType === "system_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "违规分析"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    RowLayout {
                        Text { text: "年份:" }
                        SpinBox {
                            id: yearSpinBox
                            from: 2020
                            to: 2030
                            value: new Date().getFullYear()
                        }
                        Text { text: "月份:" }
                        SpinBox {
                            id: monthSpinBox
                            from: 1
                            to: 12
                            value: new Date().getMonth() + 1
                        }
                        Button {
                            text: "查询"
                            onClicked: {
                                apiClient.getViolationAnalysis(yearSpinBox.value, monthSpinBox.value)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 300
                        border.color: "gray"
                        border.width: 1
                        radius: 5

                        Text {
                            anchors.centerIn: parent
                            text: "违规分析结果将显示在这里"
                            color: "gray"
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: parkingLotModel
    }

    ListModel {
        id: spaceModel
    }

    Component.onCompleted: {
        if (userType === "system_admin") {
            apiClient.getParkingLots()
        } else if (userType === "lot_admin") {
            // Load spaces for this admin's lot
            // apiClient.getParkingSpaces(lotId)
        }
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
            }
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent
            Text {
                text: "智能停车系统 - 管理员中心"
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

