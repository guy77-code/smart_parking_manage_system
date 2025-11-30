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

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: loginPage

        Component {
            id: loginPage
            LoginPage {
                onLoginSuccess: {
                    currentUserId = userId
                    currentUserType = userType
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
                stackView: stackView
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

