#include "userpage.h"
#include "ui_userpage.h"
#include "networkmanager.h"
#include "selectparkinglotdialog.h"
#include "paymentwindow.h"
#include "historywindow.h"
#include "bookingwindow.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QMessageBox>

UserPage::UserPage(uint userId, QWidget *parent) :
    QWidget(parent),
    ui(new Ui::UserPage),
    m_userId(userId)
{
    ui->setupUi(this);

    this->resize(1000, 700);
    this->setMinimumSize(800, 600);

    ui->btn_leave->setEnabled(false);

    connect(ui->btn_park, &QPushButton::clicked, this, &UserPage::onBtnPark);
    connect(ui->btn_leave, &QPushButton::clicked, this, &UserPage::onBtnLeave);
    connect(ui->btn_reserve, &QPushButton::clicked, this, &UserPage::onBtnReserve);
    connect(ui->btn_view_history, &QPushButton::clicked, this, &UserPage::onBtnViewHistory);
    connect(ui->btn_refresh, &QPushButton::clicked, this, &UserPage::handleRefreshClicked);

    // ✅ 连退出按钮
    connect(ui->btn_logout, &QPushButton::clicked, this, &UserPage::onBtnLogoutClicked);

    connect(&m_autoRefreshTimer, &QTimer::timeout, this, &UserPage::refreshStatus);
    m_autoRefreshTimer.start(30000);

    refreshStatus();
}

UserPage::~UserPage()
{
    delete ui;
}

void UserPage::onBtnLogoutClicked()
{
    emit requestLogout();
}

void UserPage::handleRefreshClicked() {
    refreshStatus();
}

/**
 * ✅ 修改后的刷新状态逻辑：
 * - 获取当前停车记录：GET /api/parking/:user_id/active-parking
 * - 预订与订单部分先显示“暂无信息”
 */
void UserPage::refreshStatus() {
    NetworkManager *net = NetworkManager::instance();
    QUrl url(QString("/api/parking/%1/active-parking").arg(m_userId));
    QNetworkReply *reply = net->get(url);
    connect(reply, &QNetworkReply::finished, this, &UserPage::onUserStatusReply);

    ui->label_status->setText("加载中...");
    ui->label_reservation->setText("暂无预订信息");
    ui->label_order->setText("暂无待支付订单");
}

void UserPage::onUserStatusReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() == QNetworkReply::ContentNotFoundError) {
        // 没有在场记录
        ui->label_status->setText("当前暂无车辆在使用停车场");
        ui->btn_park->setEnabled(true);
        ui->btn_leave->setEnabled(false);
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        ui->label_status->setText("状态加载失败");
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) {
        ui->label_status->setText("数据格式错误");
        return;
    }

    QJsonArray arr = doc.array();
    if (arr.isEmpty()) {
        ui->label_status->setText("当前暂无车辆在使用停车场");
        ui->btn_park->setEnabled(true);
        ui->btn_leave->setEnabled(false);
        return;
    }

    // 默认只显示第一个在场记录
    QJsonObject record = arr.first().toObject();
    QString lotName = record.value("lot_name").toString();
    if (lotName.isEmpty() && record.contains("Lot") && record["Lot"].isObject()) {
        lotName = record["Lot"].toObject().value("name").toString();
    }

    ui->label_status->setText(QString("当前车辆停放于：%1").arg(lotName.isEmpty() ? "未知停车场" : lotName));
    ui->btn_park->setEnabled(false);
    ui->btn_leave->setEnabled(true);
}

void UserPage::onBtnPark() {
    showSelectParkingDialog();
}

void UserPage::showSelectParkingDialog() {
    SelectParkingLotDialog dlg(this);
    if (dlg.exec() == QDialog::Accepted) {
        uint lotId = dlg.selectedLotId();
        uint vehicleId = dlg.selectedVehicleId();

        QJsonObject payload;
        payload["user_id"] = (int)m_userId;
        payload["lot_id"] = (int)lotId;
        payload["vehicle_id"] = (int)vehicleId;

        NetworkManager *net = NetworkManager::instance();
        QNetworkReply *reply = net->postJson(QUrl("/api/parking/entry"), payload);
        connect(reply, &QNetworkReply::finished, this, &UserPage::onEnterReply);
    }
}

void UserPage::onEnterReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        showMessage("停车失败", reply->errorString());
        return;
    }

    QJsonObject obj = QJsonDocument::fromJson(data).object();
    if (obj.contains("message")) {
        showMessage("停车", obj["message"].toString());
    } else {
        showMessage("停车", "停车成功");
    }
    refreshStatus();
}

void UserPage::onBtnLeave() {
    QJsonObject payload;
    payload["user_id"] = (int)m_userId;
    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("/api/parking/exit"), payload);
    connect(reply, &QNetworkReply::finished, this, &UserPage::onExitReply);
}


void UserPage::onExitReply() {
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        showMessage("离开失败", reply->errorString());
        return;
    }

    QJsonObject obj = QJsonDocument::fromJson(data).object();
    if (obj.contains("order_id")) {
        uint orderId = (uint)obj["order_id"].toInt();
        openPaymentWindow(orderId);
    } else {
        showMessage("离开", "离开成功（无待支付订单）");
    }
    refreshStatus();
}

void UserPage::openPaymentWindow(uint orderId) {
    PaymentWindow *win = new PaymentWindow(orderId, this);
    connect(win, &PaymentWindow::paymentSucceeded, this, [this]() {
        auto placeholder =
            QMessageBox::information(this, "支付成功", "支付完成，离开成功。");
        refreshStatus();
    });
    win->setAttribute(Qt::WA_DeleteOnClose);
    win->show();
}

void UserPage::onBtnReserve() {
    BookingWindow dlg(m_userId, this);
    if (dlg.exec() == QDialog::Accepted) {
        QMessageBox::information(this, "预订", "预订成功，已更新您的预订信息。");
        refreshStatus();
    }
}

void UserPage::onBtnViewHistory() {
    HistoryWindow *hw = new HistoryWindow(m_userId, this);
    hw->setAttribute(Qt::WA_DeleteOnClose);
    hw->show();
}

void UserPage::onGenerateViolationReply() {}

void UserPage::showMessage(const QString &title, const QString &msg) {
    QMessageBox::information(this, title, msg);
}
