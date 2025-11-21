#include "paymentwindow.h"
#include "ui_paymentwindow.h"
#include "networkmanager.h"
#include <QMessageBox>

PaymentWindow::PaymentWindow(uint orderId, QWidget *parent) :
    QWidget(parent),
    ui(new Ui::PaymentWindow),
    m_orderId(orderId)
{
    ui->setupUi(this);
    connect(ui->btn_pay, &QPushButton::clicked, this, &PaymentWindow::onPayClicked);
    connect(ui->btn_cancel, &QPushButton::clicked, this, &PaymentWindow::onCancelClicked);
    loadOrderInfo();
}

PaymentWindow::~PaymentWindow()
{
    delete ui;
}

void PaymentWindow::loadOrderInfo() {
    // GET /api/payment/{orderId} (后端如无该接口可跳过)
    ui->label_info->setText(QString("订单号：%1\n请点击模拟支付完成支付流程（第三方支付在后续接入）。").arg(m_orderId));
}

void PaymentWindow::onPayClicked() {
    // 模拟支付成功：POST /api/payment/pay
    QJsonObject payload;
    payload["order_id"] = (int)m_orderId;
    payload["method"] = QString("wallet");
    payload["amount"] = 0; // 可从后端获取
    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("/api/payment/pay"), payload);
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        QByteArray data = reply->readAll();
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            QMessageBox::warning(this, "支付失败", reply->errorString());
            return;
        }
        // 通知父窗口
        emit paymentSucceeded();
        close();
    });
}

void PaymentWindow::onCancelClicked() {
    close();
}
