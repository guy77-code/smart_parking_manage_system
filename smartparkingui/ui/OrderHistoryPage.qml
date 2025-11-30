import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: orderHistoryPage
    title: "订单历史"

    property var stackView: null

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Text {
            text: "订单历史"
            font.pixelSize: 24
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: paymentModel
            delegate: Rectangle {
                width: ListView.view.width
                height: 100
                border.color: "gray"
                border.width: 1
                radius: 5

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    ColumnLayout {
                        Text {
                            text: "订单ID: " + model.orderId
                            font.pixelSize: 14
                        }
                        Text {
                            text: "金额: ¥" + (model.amount || 0).toFixed(2)
                            font.pixelSize: 14
                        }
                        Text {
                            text: "支付方式: " + (model.method || "")
                            font.pixelSize: 12
                            color: "gray"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        Text {
                            text: model.paymentStatus === 1 ? "已支付" : "待支付"
                            font.pixelSize: 14
                            color: model.paymentStatus === 1 ? "green" : "orange"
                        }
                        Text {
                            text: model.payTime || ""
                            font.pixelSize: 12
                            color: "gray"
                        }
                    }

                    Button {
                        text: "支付"
                        visible: model.paymentStatus === 0
                        onClicked: {
                            stackView.push(paymentPage, {
                                orderId: model.orderId,
                                type: "parking",
                                amount: model.amount
                            })
                        }
                    }
                }
            }
        }
    }

    ListModel {
        id: paymentModel
    }

    Component.onCompleted: {
        apiClient.getUserPaymentRecords(1, 50)
    }

    Connections {
        target: apiClient

        function onPaymentRecordsReceived(response) {
            paymentModel.clear()
            var records = response.records || []
            for (var i = 0; i < records.length; i++) {
                paymentModel.append(records[i])
            }
        }
    }
}

