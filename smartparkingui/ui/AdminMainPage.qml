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
        // 数据分析和违规分析仅对停车场管理员开放（后端分析接口依赖 lot_id）
        TabButton { text: "数据分析"; visible: userType === "lot_admin" }
        TabButton { text: "违规分析"; visible: userType === "lot_admin" }
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
                            onClicked: addLotDialog.open()
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
                                // 兼容后端字段 hourly_rate
                                Text {
                                    text: {
                                        var rate = 0
                                        if (model.hourlyRate !== undefined)
                                            rate = model.hourlyRate
                                        else if (model.hourly_rate !== undefined)
                                            rate = model.hourly_rate
                                        return "费率: ¥" + rate + "/小时"
                                    }
                                }
                            }
                            Item { Layout.fillWidth: true }
                            Button {
                                text: "查看详情"
                                onClicked: {
                                    if (!stackView) {
                                        console.log("stackView is null, cannot navigate to detail page")
                                        return
                                    }
                                    // 系统管理员查看停车场详情时，优先展示车位可视化
                                    var lotIdValue = model.lotId !== undefined ? model.lotId : (model.lot_id || 0)
                                    stackView.push(Qt.resolvedUrl("ParkingVisualizationPage.qml"), {
                                                       lotId: lotIdValue,
                                                       stackView: stackView
                                                   })
                                }
                            }
                        }
                    }
                    }
                }
            }
        }

        // Space Management (Lot Admin) - 实时车位可视化
        ScrollView {
            visible: userType === "lot_admin"
            Item {
                anchors.fill: parent
                anchors.margins: 20
                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    Text {
                        text: "车位管理（实时可视化）"
                        font.pixelSize: 20
                        font.bold: true
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        id: lotSpaceLoader
                        source: "ParkingVisualizationPage.qml"
                        onLoaded: {
                            if (!item)
                                return
                            var info = authManager.userInfo
                            var lotIdValue = info && (info.lot_id || info.lotId || 0)
                            item.lotId = lotIdValue
                            item.stackView = stackView
                        }
                    }
                }
            }
        }

        // Data Analysis（仅停车场管理员）
        ScrollView {
            visible: userType === "lot_admin"
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
                                // 接受用户输入的日期或完整时间，统一转换为RFC3339
                                function normalizeTime(t, isEnd) {
                                    if (!t || t.length === 0)
                                        return ""
                                    if (t.indexOf("T") >= 0)
                                        return t
                                    return t + (isEnd ? "T23:59:59Z" : "T00:00:00Z")
                                }
                                var start = normalizeTime(startTimeField.text, false)
                                var end = normalizeTime(endTimeField.text, true)
                                apiClient.getOccupancyAnalysis(start, end)
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

        // Violation Analysis（仅停车场管理员）
        ScrollView {
            visible: userType === "lot_admin"
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
            // Loader 中的 ParkingVisualizationPage 会在加载完成后自行读取 lot_id 并加载车位
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
                return
            }
            // 添加停车场成功后刷新列表
            var url = response.url || ""
            if (url.indexOf("/api/v2/addparkinglot") >= 0) {
                apiClient.getParkingLots()
            }
        }
    }

    // 添加停车场对话框
    Dialog {
        id: addLotDialog
        modal: true
        title: "添加停车场"
        standardButtons: Dialog.Ok | Dialog.Cancel

        property alias lotName: lotNameField.text
        property alias lotAddress: lotAddressField.text
        property alias lotLevels: levelsField.text
        property alias lotSpaces: spacesField.text
        property alias lotRate: rateField.text
        property alias lotDesc: descField.text

        onAccepted: {
            var name = lotName.trim()
            var address = lotAddress.trim()
            var levels = parseInt(lotLevels) || 1
            var spaces = parseInt(lotSpaces) || 0
            var rate = parseFloat(lotRate) || 0
            var desc = lotDesc.trim()

            if (name.length === 0 || address.length === 0) {
                console.log("停车场名称和地址不能为空")
                return
            }

            apiClient.addParkingLot(name, address, levels, spaces, rate, 1, desc)
        }

        contentItem: ColumnLayout {
            anchors.margins: 20
            spacing: 10

            TextField {
                id: lotNameField
                Layout.fillWidth: true
                placeholderText: "停车场名称"
            }
            TextField {
                id: lotAddressField
                Layout.fillWidth: true
                placeholderText: "停车场地址"
            }
            TextField {
                id: levelsField
                Layout.fillWidth: true
                placeholderText: "总楼层数（如：3）"
                inputMethodHints: Qt.ImhDigitsOnly
            }
            TextField {
                id: spacesField
                Layout.fillWidth: true
                placeholderText: "总车位数（如：200）"
                inputMethodHints: Qt.ImhDigitsOnly
            }
            TextField {
                id: rateField
                Layout.fillWidth: true
                placeholderText: "小时费率（如：5.0）"
            }
            TextField {
                id: descField
                Layout.fillWidth: true
                placeholderText: "说明（可选）"
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

