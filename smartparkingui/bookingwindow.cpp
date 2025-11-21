#include "bookingwindow.h"
#include "ui_bookingwindow.h"
#include "networkmanager.h"

#include <QMessageBox>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QListWidgetItem>

BookingWindow::BookingWindow(uint userId, QWidget *parent) :
    QDialog(parent),
    ui(new Ui::BookingWindow),
    m_userId(userId),
    m_selectedLotId(0)
{
    ui->setupUi(this);
    this->resize(1100, 750);
    this->setWindowTitle("预订车位");
    this->setSizeGripEnabled(true);

    ui->combo_space_type->setEnabled(false);
    ui->datetime_start->setDateTime(QDateTime::currentDateTime());
    ui->datetime_end->setDateTime(QDateTime::currentDateTime().addSecs(3600));

    connect(ui->btn_refresh, &QPushButton::clicked, this, &BookingWindow::loadNearbyParkingLots);
    connect(ui->btn_confirm, &QPushButton::clicked, this, &BookingWindow::onConfirmBooking);
    connect(ui->btn_cancel, &QPushButton::clicked, this, &BookingWindow::reject);
    connect(ui->list_lots, &QListWidget::itemClicked, this, &BookingWindow::onLotSelected);

    loadNearbyParkingLots();
}

BookingWindow::~BookingWindow()
{
    delete ui;
}

void BookingWindow::loadNearbyParkingLots()
{
    ui->list_lots->clear();
    ui->combo_space_type->clear();
    ui->combo_space_type->setEnabled(false);

    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->get(QUrl("/api/parking/space-types"));
    connect(reply, &QNetworkReply::finished, this, &BookingWindow::onParkingLotsReply);

    ui->label_status->setText("加载附近停车场中...");
}

void BookingWindow::onParkingLotsReply()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        ui->label_status->setText("加载停车场失败");
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) {
        ui->label_status->setText("数据格式错误");
        return;
    }

    QStringList lots = {"中央停车场", "东门停车场", "西区停车场"};
    for (int i = 0; i < lots.size(); ++i) {
        QListWidgetItem *item = new QListWidgetItem(QString("%1（编号：%2）").arg(lots[i]).arg(i + 1));
        item->setData(Qt::UserRole, i + 1);
        ui->list_lots->addItem(item);
    }

    ui->label_status->setText("请选择停车场以查看车位类型");
}

void BookingWindow::onLotSelected()
{
    QListWidgetItem *item = ui->list_lots->currentItem();
    if (!item) return;

    m_selectedLotId = item->data(Qt::UserRole).toUInt();
    ui->label_status->setText(QString("加载停车场 %1 的车位类型...").arg(m_selectedLotId));

    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->get(QUrl(QString("/api/parking/%1/spaces").arg(m_selectedLotId)));
    connect(reply, &QNetworkReply::finished, this, &BookingWindow::onSpaceTypesReply);
}

void BookingWindow::onSpaceTypesReply()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        showMessage("错误", "加载车位类型失败，请检查网络或稍后重试。");
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isArray()) {
        showMessage("错误", "车位类型数据格式错误。");
        return;
    }

    ui->combo_space_type->clear();
    QJsonArray arr = doc.array();
    for (auto v : arr) {
        if (v.isObject()) {
            QString type = v.toObject().value("space_type").toString();
            ui->combo_space_type->addItem(type);
        }
    }

    ui->combo_space_type->setEnabled(true);
    ui->label_status->setText("请选择车位类型和时间段");
}

void BookingWindow::onConfirmBooking()
{
    if (m_selectedLotId == 0) {
        showMessage("提示", "请先选择停车场。");
        return;
    }
    if (!ui->combo_space_type->isEnabled() || ui->combo_space_type->currentText().isEmpty()) {
        showMessage("提示", "请选择车位类型。");
        return;
    }

    QDateTime start = ui->datetime_start->dateTime();
    QDateTime end = ui->datetime_end->dateTime();
    if (end <= start) {
        showMessage("提示", "离开时间必须晚于开始时间。");
        return;
    }

    QJsonObject payload;
    payload["user_id"] = (int)m_userId;
    payload["vehicle_id"] = 1;
    payload["lot_id"] = (int)m_selectedLotId;
    payload["start_time"] = start.toString(Qt::ISODate);
    payload["end_time"] = end.toString(Qt::ISODate);

    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->postJson(QUrl("/api/v4/booking/create"), payload);
    connect(reply, &QNetworkReply::finished, this, &BookingWindow::onBookingReply);

    ui->label_status->setText("正在创建预订...");
}

void BookingWindow::onBookingReply()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray data = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        showMessage("预订失败", reply->errorString());
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject obj = doc.object();

    if (obj.contains("ReservationCode")) {
        QString code = obj["ReservationCode"].toString();
        showMessage("预订成功", QString("预订成功！您的预订编号：%1").arg(code));
    } else {
        showMessage("预订成功", "预订已成功提交！");
    }

    accept();
}

void BookingWindow::showMessage(const QString &title, const QString &msg)
{
    QMessageBox box(QMessageBox::Information, title, msg, QMessageBox::Ok, this);
    box.setMinimumWidth(420);

    QList<QLabel*> labels = box.findChildren<QLabel*>();
    for (QLabel *label : labels) {
        label->setWordWrap(true);
        label->setMinimumWidth(380);
    }

    box.exec();
}
