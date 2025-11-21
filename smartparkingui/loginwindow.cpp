#include "loginwindow.h"
#include "ui_loginwindow.h"
#include "networkmanager.h"
#include "registerwindow.h"  // 新增注册窗口头文件
#include "userpage.h"
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QApplication>


LoginWindow::LoginWindow(QWidget *parent)
    : QDialog(parent), ui(new Ui::LoginWindow), registerWindow(nullptr) {
    ui->setupUi(this);

    // 设置窗口固定大小
    setFixedSize(400, 350);

    stack = new QStackedWidget(this);
    stack->setGeometry(this->rect());  // 让它覆盖整个窗口
    stack->addWidget(ui->centralwidget);  // 0 = 登录页
    stack->setCurrentIndex(0);

    // 确保输入法可用
    this->setAttribute(Qt::WA_InputMethodEnabled, true);

    // 为输入框启用输入法
    ui->edit_username->setAttribute(Qt::WA_InputMethodEnabled, true);
    ui->edit_password->setAttribute(Qt::WA_InputMethodEnabled, true);

    // 设置输入法提示（允许中文输入）
    ui->edit_username->setInputMethodHints(Qt::ImhNoPredictiveText);
    ui->edit_password->setInputMethodHints(Qt::ImhNoPredictiveText);
    // 连接信号槽
    connect(ui->btn_login, &QPushButton::clicked, this, &LoginWindow::onLoginButtonClicked);
    connect(ui->btn_exit, &QPushButton::clicked, this, &LoginWindow::onExitButtonClicked);
    connect(ui->btn_register, &QPushButton::clicked, this, &LoginWindow::onRegisterButtonClicked);
}

LoginWindow::~LoginWindow() {
    if (registerWindow) {
        delete registerWindow;
    }
    delete ui;
}

void LoginWindow::onLoginButtonClicked() {
    QString username = ui->edit_username->text().trimmed();
    QString password = ui->edit_password->text().trimmed();

    if (username.isEmpty() || password.isEmpty()) {
        ui->label_status->setText("请输入完整信息。");
        return;
    }

    handleUserLogin(username, password);
}

void LoginWindow::handleUserLogin(const QString &username, const QString &password) {
    QJsonObject payload;
    payload["phone"] = username;
    payload["password"] = password;

    // 发送到普通用户登录接口
    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("http://127.0.0.1:8080/api/v1/login"), payload);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onLoginReply(reply); });
}

void LoginWindow::onLoginReply(QNetworkReply *reply) {
    QByteArray response = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        ui->label_status->setText("登录失败: " + reply->errorString());
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(response);
    QJsonObject obj = doc.object();

    if (obj.contains("user")) {
        QJsonObject user = obj["user"].toObject();
        int id = user["id"].toInt();
        QString uname = user["username"].toString();
        QString phone = user["phone"].toString();
        QString token = obj["token"].toString();

        if (obj["message"].toString() == "Login success") {
            QMessageBox::information(this, "登录成功", "欢迎 " + uname);

            // ✅ 创建用户页并加入 stack
            if (!userPage) {
                userPage = new UserPage(id, this);
                stack->addWidget(userPage);  // index = 1
            }

            stack->setCurrentWidget(userPage); // ✅ 切换界面

        }

        return;
    }

    ui->label_status->setText("登录失败，请检查手机号和密码。");
}


void LoginWindow::onExitButtonClicked() {
    QApplication::quit();
}

void LoginWindow::onRegisterButtonClicked() {
    // 创建注册窗口（如果尚未创建）
    if (!registerWindow) {
        registerWindow = new RegisterWindow(this);
        connect(registerWindow, &RegisterWindow::backToLogin, this, &LoginWindow::onBackToLogin);
    }

    // 显示注册窗口，隐藏登录窗口
    registerWindow->show();
    this->hide();
}

void LoginWindow::onBackToLogin() {
    // 显示登录窗口，清除状态信息
    this->show();
    ui->label_status->clear();
    if (registerWindow) {
        registerWindow->hide();
    }
}
