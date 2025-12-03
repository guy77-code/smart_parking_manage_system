import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

ApplicationWindow {
    id: window
    width: 1200
    height: 800
    visible: true
    title: "智能停车系统"

    property int currentUserId: 0
    property string currentUserType: ""

    // 全局窗口控制栏（最小化 / 关闭），在所有页面顶部显示
    header: ToolBar {
        RowLayout {
            anchors.fill: parent

            Text {
                text: "智能停车系统"
                font.pixelSize: 16
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                leftPadding: 8
            }

            Item { Layout.fillWidth: true }

            // 最小化按钮
            Button {
                text: "—"
                width: 40
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                onClicked: window.showMinimized()
            }

            // 关闭按钮
            Button {
                text: "×"
                width: 40
                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                onClicked: Qt.quit()
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: loginPage

        Component {
            id: loginPage
            LoginPage {
                onLoginSuccess: function(userId, userType) {
                    window.currentUserId = userId
                    window.currentUserType = userType
                    if (userType === "user") {
                        var page = userMainPage.createObject(stackView)
                        page.stackView = stackView
                        stackView.push(page)
                    } else {
                        var adminPage = adminMainPage.createObject(stackView)
                        adminPage.stackView = stackView
                        stackView.push(adminPage)
                    }
                }
            }
        }

        Component {
            id: userMainPage
            UserMainPage {
                userId: window.currentUserId
                onLogout: {
                    authManager.clearAuth()
                    stackView.pop(null)
                }
            }
        }

        Component {
            id: adminMainPage
            AdminMainPage {
                userId: window.currentUserId
                userType: window.currentUserType
                stackView: stackView
                onLogout: {
                    authManager.clearAuth()
                    stackView.pop(null)
                }
            }
        }

        Component {
            id: bookingPage
            BookingPage {
                userId: window.currentUserId
                stackView: stackView
            }
        }

        Component {
            id: parkingVisualizationPage
            ParkingVisualizationPage {
                stackView: stackView
            }
        }

        Component {
            id: paymentPage
            PaymentPage {
                stackView: stackView
            }
        }

        Component {
            id: violationPage
            ViolationPage {
                userId: window.currentUserId
                stackView: stackView
            }
        }

        Component {
            id: orderHistoryPage
            OrderHistoryPage {
                stackView: stackView
            }
        }

        Component {
            id: adminDataPage
            AdminDataPage {
            }
        }
    }
}

