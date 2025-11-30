import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: violationPage
    title: "违规记录"

    property int userId: 0

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "违规记录"
            font.pixelSize: 24
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: violationModel
            delegate: Rectangle {
                width: ListView.view.width
                height: 120
                border.color: "gray"
                border.width: 1
                radius: 5

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 5

                    Text {
                        text: "违规类型: " + (model.violationType || "")
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: "违规时间: " + (model.violationTime || "")
                        font.pixelSize: 14
                    }

                    Text {
                        text: "罚款金额: ¥" + (model.fineAmount || 0).toFixed(2)
                        font.pixelSize: 14
                        color: "red"
                    }

                    Text {
                        text: "状态: " + (model.status === 1 ? "已处理" : "未处理")
                        font.pixelSize: 14
                        color: model.status === 1 ? "green" : "orange"
                    }

                    RowLayout {
                        Button {
                            text: "支付罚款"
                            visible: model.status === 0
                            onClicked: {
                                apiClient.payViolationFine(model.violationId)
                            }
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: violationModel
    }

    Component.onCompleted: {
        apiClient.getUserViolations(userId)
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            if (response.hasOwnProperty("error")) {
                console.log("Error:", response.error)
                return
            }

            var data = response.data || []
            if (Array.isArray(data)) {
                violationModel.clear()
                for (var i = 0; i < data.length; i++) {
                    violationModel.append(data[i])
                }
            }
        }
    }
}

