import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SmartParking 1.0

Page {
    id: loginPage
    title: "登录"

    signal loginSuccess(int userId, string userType)

    property bool isUserLogin: true
    property bool isRegisterMode: false

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width * 0.4, 400)
        spacing: 20

        Text {
            Layout.fillWidth: true
            text: isRegisterMode ? "用户注册" : (isUserLogin ? "用户登录" : "管理员登录")
            font.pixelSize: 24
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        // User type selection
        RowLayout {
            Layout.fillWidth: true
            visible: !isRegisterMode

            Button {
                text: "用户"
                Layout.fillWidth: true
                checked: isUserLogin
                checkable: true
                onClicked: isUserLogin = true
            }

            Button {
                text: "管理员"
                Layout.fillWidth: true
                checked: !isUserLogin
                checkable: true
                onClicked: isUserLogin = false
            }
        }

        // Phone input
        TextField {
            id: phoneField
            Layout.fillWidth: true
            placeholderText: "手机号"
            inputMethodHints: Qt.ImhDigitsOnly
        }

        // Password input
        TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholderText: "密码"
            echoMode: TextField.Password
            visible: !isRegisterMode || isUserLogin
        }

        // Username (for registration)
        TextField {
            id: usernameField
            Layout.fillWidth: true
            placeholderText: "用户名"
            visible: isRegisterMode && isUserLogin
        }

        // Email (for registration)
        TextField {
            id: emailField
            Layout.fillWidth: true
            placeholderText: "邮箱（可选）"
            visible: isRegisterMode && isUserLogin
        }

        // Verification code
        RowLayout {
            Layout.fillWidth: true
            visible: isUserLogin && !isRegisterMode

            TextField {
                id: codeField
                Layout.fillWidth: true
                placeholderText: "验证码（可选）"
                inputMethodHints: Qt.ImhDigitsOnly
            }

            Button {
                text: "发送验证码"
                onClicked: {
                    if (phoneField.text.length > 0) {
                        apiClient.sendLoginCode(phoneField.text)
                    }
                }
            }
        }

        // License plate (for registration)
        TextField {
            id: licensePlateField
            Layout.fillWidth: true
            placeholderText: "车牌号（必填）"
            visible: isRegisterMode && isUserLogin
        }

        // Login/Register button
        Button {
            Layout.fillWidth: true
            text: isRegisterMode ? "注册" : "登录"
            enabled: phoneField.text.length > 0 && (isRegisterMode ? (passwordField.text.length > 0 && licensePlateField.text.length > 0) : true)
            onClicked: {
                if (isRegisterMode && isUserLogin) {
                    // Register user
                    var userData = {
                        "username": usernameField.text,
                        "password": passwordField.text,
                        "phone": phoneField.text,
                        "email": emailField.text || ""
                    }
                    var vehicles = [{
                        "license_plate": licensePlateField.text,
                        "brand": "",
                        "model": "",
                        "color": ""
                    }]
                    apiClient.registerUser(userData, vehicles)
                } else if (isUserLogin) {
                    // User login
                    if (codeField.text.length > 0) {
                        apiClient.login(phoneField.text, "", codeField.text)
                    } else {
                        apiClient.login(phoneField.text, passwordField.text)
                    }
                } else {
                    // Admin login
                    apiClient.adminLogin(phoneField.text, passwordField.text)
                }
            }
        }

        // Switch to register mode
        Button {
            Layout.fillWidth: true
            text: isRegisterMode ? "返回登录" : "注册新用户"
            flat: true
            onClicked: isRegisterMode = !isRegisterMode
        }

        // Status message
        Text {
            id: statusText
            Layout.fillWidth: true
            color: "red"
            wrapMode: Text.Wrap
            visible: text.length > 0
        }
    }

    Connections {
        target: apiClient

        function onRequestFinished(response) {
            var url = response.url || ""
            var httpStatus = response.http_status || 200

            // 针对登录/注册请求做专门处理
            var isLoginRequest = url.indexOf("/api/v1/login") >= 0 || url.indexOf("/admin/login") >= 0
            var isRegisterRequest = url.indexOf("/api/v1/register") >= 0

            if (httpStatus >= 200 && httpStatus < 300) {
                if (isRegisterMode && isRegisterRequest) {
                    statusText.color = "green"
                    statusText.text = "注册成功！"
                    Qt.callLater(function() {
                        isRegisterMode = false
                        statusText.text = ""
                        statusText.color = "red"
                    })
                } else if (isLoginRequest && !isRegisterMode) {
                    // Login success
                    var token = response.token || ""
                    var user = response.user || response.admin_info || {}
                    var role = response.role || "user"
                    var userId = user.id || user.admin_id || 0

                    if (token.length > 0) {
                        var userType = role === "system" ? "system_admin"
                                                         : (role === "lot_admin" ? "lot_admin" : "user")
                        authManager.saveToken(token, userType, user)
                        loginSuccess(userId, userType)
                    } else {
                        statusText.text = "登录失败：服务器未返回 token"
                    }
                }
            } else if (isLoginRequest || isRegisterRequest) {
                // 登录/注册失败的友好错误提示
                var rawError = response.error || ""
                var backendMsg = response.message || ""

                if (httpStatus === 401 || httpStatus === 403) {
                    if (isRegisterMode) {
                        statusText.text = "注册失败：请检查输入信息是否正确"
                    } else if (url.indexOf("/admin/login") >= 0) {
                        statusText.text = "管理员登录失败：账号或密码错误"
                    } else {
                        statusText.text = "登录失败：手机号或密码错误"
                    }
                } else if (rawError && rawError.indexOf("需要验证") >= 0) {
                    // Qt 网络层的“主机需要验证”等信息，改成用户可理解的提示
                    if (url.indexOf("/admin/login") >= 0) {
                        statusText.text = "管理员登录失败：账号或密码错误"
                    } else {
                        statusText.text = "登录失败：请检查手机号或密码"
                    }
                } else if (httpStatus === 0) {
                    statusText.text = "无法连接服务器，请确认后端服务已启动（http://127.0.0.1:8080）"
                } else {
                    statusText.text = backendMsg || rawError || "操作失败（HTTP " + httpStatus + "）"
                }
            }
        }

        // 兜底：监听通用 requestError，把底层错误转为友好提示
        function onRequestError(error) {
            // 只在本页面关注登录/注册相关错误
            if (isRegisterMode) {
                statusText.text = "注册失败：" + error
            } else if (isUserLogin) {
                if (error.indexOf("需要验证") >= 0) {
                    statusText.text = "登录失败：手机号或密码错误"
                } else {
                    statusText.text = "登录失败：" + error
                }
            } else {
                if (error.indexOf("需要验证") >= 0) {
                    statusText.text = "管理员登录失败：账号或密码错误"
                } else {
                    statusText.text = "管理员登录失败：" + error
                }
            }
        }
    }
}

