import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: adminDataPage
    title: "数据分析"

    property int lotId: 0
    // 用于返回管理员主页面
    property var stackView: null

    // 显示数据的文本
    property string occupancyDataText: "使用率分析结果将显示在这里"
    property string violationDataText: "违规分析结果将显示在这里"
    property string reportDataText: "报表内容将显示在这里"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // 返回管理员主页面按钮
        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "返回管理员主页"
                onClicked: {
                    if (stackView) {
                        stackView.pop()
                    } else {
                        console.log("stackView is null, cannot pop AdminDataPage")
                    }
                }
            }
            Item { Layout.fillWidth: true }
        }

        TabBar {
            id: tabBar
            Layout.fillWidth: true

            TabButton { text: "使用率分析" }
            TabButton { text: "违规分析" }
            TabButton { text: "报表生成" }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // 使用率分析
            ScrollView {
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: "车位使用率分析"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "开始时间:" }
                            TextField {
                                id: startTimeField
                                Layout.fillWidth: true
                                placeholderText: "2025-01-01T00:00:00Z"
                            }
                            Text { text: "结束时间:" }
                            TextField {
                                id: endTimeField
                                Layout.fillWidth: true
                                placeholderText: "2025-01-31T23:59:59Z"
                            }
                            Button {
                                text: "查询"
                                onClicked: {
                                    if (authManager.userType !== "lot_admin") {
                                        occupancyDataText = "当前登录为系统管理员账号，车位使用率分析仅支持停车场管理员。"
                                        return
                                    }
                                    // 允许输入日期或完整时间，自动转换为RFC3339
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
                            Layout.preferredHeight: 400
                            border.color: "gray"
                            border.width: 1
                            radius: 5

                            Text {
                                anchors.centerIn: parent
                                text: occupancyDataText
                                color: "gray"
                            }
                        }
                    }
                }
            }

            // 违规分析
            ScrollView {
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: "违规行为分析"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
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
                                    if (authManager.userType !== "lot_admin") {
                                        violationDataText = "当前登录为系统管理员账号，违规分析仅支持停车场管理员。"
                                        return
                                    }
                                    apiClient.getViolationAnalysis(yearSpinBox.value, monthSpinBox.value)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            border.color: "gray"
                            border.width: 1
                            radius: 5

                            Text {
                                anchors.centerIn: parent
                                text: violationDataText
                                color: "gray"
                            }
                        }
                    }
                }
            }

            // 报表生成
            ScrollView {
                Item {
                    anchors.fill: parent
                    anchors.margins: 20

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 20

                        Text {
                            text: "报表生成"
                            font.pixelSize: 20
                            font.bold: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "报表类型:" }
                            ComboBox {
                                id: reportTypeComboBox
                                model: ["monthly", "annual"]
                            }
                            Text { text: "年份:" }
                            SpinBox {
                                id: reportYearSpinBox
                                from: 2020
                                to: 2030
                                value: new Date().getFullYear()
                            }
                            Text {
                                text: "月份:"
                                visible: reportTypeComboBox.currentText === "monthly"
                            }
                            SpinBox {
                                id: reportMonthSpinBox
                                from: 1
                                to: 12
                                value: new Date().getMonth() + 1
                                visible: reportTypeComboBox.currentText === "monthly"
                            }
                            Button {
                                text: "生成报表"
                                onClicked: {
                                    if (authManager.userType !== "lot_admin") {
                                        reportDataText = "当前登录为系统管理员账号，报表生成仅支持停车场管理员。"
                                        return
                                    }
                                    var month = reportTypeComboBox.currentText === "monthly" ? reportMonthSpinBox.value : 0
                                    apiClient.generateReport(reportTypeComboBox.currentText, reportYearSpinBox.value, month)
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 400
                            border.color: "gray"
                            border.width: 1
                            radius: 5

                            Text {
                                anchors.centerIn: parent
                                text: reportDataText
                                color: "gray"
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            if (response.hasOwnProperty("data")) {
                var data = response.data
                // 根据当前 Tab 更新对应显示内容
                if (tabBar.currentIndex === 0) {
                    occupancyDataText = JSON.stringify(data, null, 2)
                } else if (tabBar.currentIndex === 1) {
                    violationDataText = JSON.stringify(data, null, 2)
                } else if (tabBar.currentIndex === 2) {
                    reportDataText = JSON.stringify(response.report || data, null, 2)
                }
            }
        }
    }
}

