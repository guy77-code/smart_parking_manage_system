#include "registerwindow.h"
#include "ui_registerwindow.h"
#include "networkmanager.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QMessageBox>
#include <QRegularExpressionValidator>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>

RegisterWindow::RegisterWindow(QWidget *parent)
    : QDialog(parent), ui(new Ui::RegisterWindow) {
    ui->setupUi(this);

    //允许改变窗口大小
    this->setWindowFlags(windowFlags() | Qt::Window);
    this->setSizeGripEnabled(true);

    setWindowTitle("用户注册");
    setFixedSize(500, 600);

    connect(ui->btn_register, &QPushButton::clicked, this, &RegisterWindow::onRegisterButtonClicked);
    connect(ui->btn_back, &QPushButton::clicked, this, &RegisterWindow::onBackButtonClicked);

    // 基本输入验证（允许中文）
    QRegularExpression usernameRegex("^.{3,50}$");
    ui->edit_username->setValidator(new QRegularExpressionValidator(usernameRegex, this));

    QRegularExpression passwordRegex("^.{6,100}$");
    ui->edit_password->setValidator(new QRegularExpressionValidator(passwordRegex, this));
    ui->edit_confirm_password->setValidator(new QRegularExpressionValidator(passwordRegex, this));

    // 电话 11位
    QRegularExpression phoneRegex("^\\d{11}$");
    ui->edit_phone->setValidator(new QRegularExpressionValidator(phoneRegex, this));

    // 添加第一辆车辆输入行
    onAddVehicleClicked();

    connect(ui->btn_add_vehicle, &QPushButton::clicked, this, &RegisterWindow::onAddVehicleClicked);
}

RegisterWindow::~RegisterWindow() {
    delete ui;
}

bool RegisterWindow::validateInput() {
    QString username = ui->edit_username->text().trimmed();
    QString password = ui->edit_password->text().trimmed();
    QString confirmPassword = ui->edit_confirm_password->text().trimmed();
    QString phone = ui->edit_phone->text().trimmed();

    if (username.isEmpty()) { ui->label_status->setText("用户名不能为空"); return false; }
    if (username.length() < 3) { ui->label_status->setText("用户名至少3个字符"); return false; }
    if (password.isEmpty()) { ui->label_status->setText("密码不能为空"); return false; }
    if (password != confirmPassword) { ui->label_status->setText("两次密码不一致"); return false; }
    if (phone.length() != 11) { ui->label_status->setText("手机号必须11位数字"); return false; }

    // 至少一辆车
    bool hasPlate = false;
    for (auto &vf : vehicleForms) {
        if (!vf.licensePlate->text().trimmed().isEmpty()) {
            hasPlate = true;
            break;
        }
    }
    if (!hasPlate) {
        ui->label_status->setText("至少添加一辆有效车牌!");
        return false;
    }

    return true;
}

void RegisterWindow::onAddVehicleClicked() {
    QWidget *item = new QWidget();
    auto *form = new QFormLayout(item);

    VehicleForm vf;
    vf.licensePlate = new QLineEdit();
    vf.brand = new QLineEdit();
    vf.model = new QLineEdit();
    vf.color = new QLineEdit();

    form->addRow("车牌号*", vf.licensePlate);
    form->addRow("品牌", vf.brand);
    form->addRow("型号", vf.model);
    form->addRow("颜色", vf.color);

    vehicleForms.append(vf);

    ui->vehicleListLayout->addWidget(item);
}

void RegisterWindow::onRegisterButtonClicked() {
    if (validateInput()) {
        handleUserRegister();
    }
}

void RegisterWindow::handleUserRegister() {
    QJsonObject payload;

    // 用户信息对象
    QJsonObject usersList;
    usersList["username"] = ui->edit_username->text().trimmed();
    usersList["password"] = ui->edit_password->text().trimmed();
    usersList["phone"] = ui->edit_phone->text().trimmed();
    usersList["email"] = ui->edit_email->text().trimmed();
    usersList["real_name"] = ui->edit_real_name->text().trimmed();

    payload["users_list"] = usersList;

    // 车辆数组
    QJsonArray vehicles;
    for (auto &vf : vehicleForms) {
        QJsonObject v;
        QString plate = vf.licensePlate->text().trimmed();
        if (!plate.isEmpty()) {
            v["license_plate"] = plate;
            v["brand"] = vf.brand->text().trimmed();
            v["model"] = vf.model->text().trimmed();
            v["color"] = vf.color->text().trimmed();
            vehicles.append(v);
        }
    }
    payload["vehicles"] = vehicles;

    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("http://127.0.0.1:8080/api/v1/register"), payload);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() { onRegisterReply(reply); });

    ui->label_status->setText("注册中...");
}

void RegisterWindow::onRegisterReply(QNetworkReply *reply) {
    QByteArray response = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        ui->label_status->setText("注册失败: " + reply->errorString());
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(response);
    QJsonObject obj = doc.object();

    if (obj.contains("success") && obj["success"].toBool()) {
        QMessageBox::information(this, "注册成功", "用户注册成功，请返回登录");
        emit registerSuccess();
        onBackButtonClicked();
    } else {
        QString msg = obj["message"].toString();
        ui->label_status->setText(msg.isEmpty() ? "注册失败" : msg);
    }
}

void RegisterWindow::onBackButtonClicked() {
    emit backToLogin();
}
