#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "networkmanager.h"
#include "registerwindow.h"
#include "userpage.h"
#include "systemadminpage.h"   // ✅ 新增
#include <QJsonDocument>
#include <QJsonObject>
#include <QMessageBox>
#include <QApplication>
#include <QSettings>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    resize(800, 600);
    this->setMinimumSize(600, 480);

    this->setAttribute(Qt::WA_InputMethodEnabled, true);
    ui->edit_username->setAttribute(Qt::WA_InputMethodEnabled, true);
    ui->edit_password->setAttribute(Qt::WA_InputMethodEnabled, true);

    connect(ui->btn_login, &QPushButton::clicked, this, &MainWindow::onLoginButtonClicked);
    connect(ui->btn_exit, &QPushButton::clicked, this, &MainWindow::onExitButtonClicked);
    connect(ui->btn_register, &QPushButton::clicked, this, &MainWindow::onRegisterButtonClicked);

    ui->stackedWidget->setCurrentIndex(0);
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::onLoginButtonClicked()
{
    QString username = ui->edit_username->text().trimmed();
    QString password = ui->edit_password->text().trimmed();

    if (username.isEmpty() || password.isEmpty()) {
        ui->label_status->setText("请输入完整信息。");
        return;
    }

    // 默认先尝试普通用户登录
    handleUserLogin(username, password);
}

void MainWindow::handleUserLogin(const QString &username, const QString &password)
{
    QJsonObject payload;
    payload["phone"] = username;
    payload["password"] = password;

    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("http://127.0.0.1:8080/api/v1/login"), payload);
    connect(reply, &QNetworkReply::finished, this, [this, reply, username, password]() {
        QByteArray response = reply->readAll();
        reply->deleteLater();

        if (reply->error() == QNetworkReply::NoError) {
            QJsonDocument doc = QJsonDocument::fromJson(response);
            QJsonObject obj = doc.object();

            // ✅ 如果包含 user 字段，则说明是普通用户登录成功
            if (obj.contains("user")) {
                QJsonObject user = obj["user"].toObject();
                int id = user["id"].toInt();
                QString uname = user["username"].toString();

                if (obj["message"].toString() == "Login success") {
                    QMessageBox::information(this, "登录成功", "欢迎用户 " + uname);

                    if (!userPage) {
                        userPage = new UserPage(id, this);
                        ui->stackedWidget->addWidget(userPage);

                        connect(userPage, &UserPage::requestLogout, this, [this]() {
                            QSettings settings("SmartParking", "Client");
                            settings.remove("token");
                            ui->edit_username->clear();
                            ui->edit_password->clear();
                            ui->label_status->clear();
                            ui->stackedWidget->setCurrentIndex(0);
                        });
                    }

                    ui->stackedWidget->setCurrentWidget(userPage);
                    return;
                }
            }
        }

        // 如果不是普通用户，则尝试管理员登录
        handleAdminLogin(username, password);
    });
}

void MainWindow::handleAdminLogin(const QString &username, const QString &password)
{
    QJsonObject payload;
    payload["phone"] = username;
    payload["password"] = password;

    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("http://127.0.0.1:8080/admin/login"), payload);

    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        QByteArray response = reply->readAll();
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            ui->label_status->setText("登录失败: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(response);
        QJsonObject obj = doc.object();

        if (obj.contains("role")) {
            QString role = obj["role"].toString();
            QString message = obj["message"].toString();
            QString token = obj["token"].toString();

            // 保存 token
            QSettings settings("SmartParking", "Client");
            settings.setValue("token", token);

            if (role == "system") {
                QMessageBox::information(this, "登录成功", "系统管理员登录成功");

                if (!systemAdminPage) {
                    systemAdminPage = new SystemAdminPage(this);
                    ui->stackedWidget->addWidget(systemAdminPage);

                    connect(systemAdminPage, &SystemAdminPage::requestLogout, this, [this]() {
                        QSettings settings("SmartParking", "Client");
                        settings.remove("token");
                        ui->edit_username->clear();
                        ui->edit_password->clear();
                        ui->label_status->clear();
                        ui->stackedWidget->setCurrentIndex(0);
                    });
                }

                ui->stackedWidget->setCurrentWidget(systemAdminPage);
                return;
            }
            else if (role == "lot_admin") {
                int lotId = obj.contains("lot_id") ? obj["lot_id"].toInt() : -1;
                QMessageBox::information(this, "登录成功", QString("停车场管理员登录成功\n关联停车场ID: %1").arg(lotId));

                // TODO: 停车场管理员页面（ParkingAdminPage）待实现
                ui->label_status->setText("停车场管理员页面开发中...");
                return;
            }
        }

        ui->label_status->setText("登录失败，请检查账号和密码。");
    });
}

void MainWindow::onExitButtonClicked()
{
    QApplication::quit();
}

void MainWindow::onRegisterButtonClicked()
{
    if (!registerWindow) {
        registerWindow = new RegisterWindow(this);
        connect(registerWindow, &RegisterWindow::backToLogin, this, &MainWindow::onBackToLogin);
    }

    registerWindow->show();
    this->hide();
}

void MainWindow::onBackToLogin()
{
    this->show();
    ui->label_status->clear();
    if (registerWindow) {
        registerWindow->hide();
    }
}
