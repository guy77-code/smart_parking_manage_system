import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: adminDataPage
    title: "数据分析"

    property int lotId: 0

    TabBar {
        id: tabBar
        width: parent.width

        TabButton { text: "使用率分析" }
        TabButton { text: "违规分析" }
        TabButton { text: "报表生成" }
    }

    StackLayout {
        anchors.top: tabBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        currentIndex: tabBar.currentIndex

        // Occupancy Analysis
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

        // Violation Analysis
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

        // Report Generation
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

    property string occupancyDataText: "使用率分析结果将显示在这里"
    property string violationDataText: "违规分析结果将显示在这里"
    property string reportDataText: "报表内容将显示在这里"

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            if (response.hasOwnProperty("data")) {
                var data = response.data
                // Update display text based on current tab
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

