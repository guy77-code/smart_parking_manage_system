#include "selectparkinglotdialog.h"
#include "ui_selectparkinglotdialog.h"
#include "networkmanager.h"
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include<QMessageBox>

SelectParkingLotDialog::SelectParkingLotDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::SelectParkingLotDialog)
{
    ui->setupUi(this);

    connect(ui->btn_ok, &QPushButton::clicked, this, &SelectParkingLotDialog::onOkClicked);
    connect(ui->btn_cancel, &QPushButton::clicked, this, &SelectParkingLotDialog::reject);

    loadParkingLots();
    // TODO: load user's vehicles (示例中添加一个占位项)
    ui->combo_vehicles->addItem("请选择车辆", QVariant(0));
    ui->combo_vehicles->addItem("粤A·示例1234", QVariant(1));
}

SelectParkingLotDialog::~SelectParkingLotDialog()
{
    delete ui;
}

void SelectParkingLotDialog::loadParkingLots() {
    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->get(QUrl("/api/v2/getparkinglots"));
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        QByteArray data = reply->readAll();
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) return;
        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isArray()) return;
        QJsonArray arr = doc.array();
        ui->table_lots->setRowCount(arr.size());
        for (int i=0;i<arr.size();++i) {
            QJsonObject obj = arr[i].toObject();
            int lotId = obj.value("lot_id").toInt();
            QString name = obj.value("name").toString();
            QString address = obj.value("address").toString();
            ui->table_lots->setItem(i, 0, new QTableWidgetItem(QString::number(lotId)));
            ui->table_lots->setItem(i, 1, new QTableWidgetItem(name));
            ui->table_lots->setItem(i, 2, new QTableWidgetItem(address));
        }
        ui->table_lots->resizeColumnsToContents();
    });
}

void SelectParkingLotDialog::onOkClicked() {
    auto sel = ui->table_lots->selectedItems();
    if (sel.isEmpty()) {
        // 取第一行作为默认
        if (ui->table_lots->rowCount() > 0) {
            m_selectedLotId = ui->table_lots->item(0,0)->text().toUInt();
        }
    } else {
        m_selectedLotId = ui->table_lots->selectedItems().first()->text().toUInt();
    }
    m_selectedVehicleId = ui->combo_vehicles->currentData().toUInt();
    if (m_selectedVehicleId == 0) {
        QMessageBox::warning(this, "请选择车辆", "请先选择一辆车辆来停车。");
        return;
    }
    accept();
}

uint SelectParkingLotDialog::selectedLotId() const { return m_selectedLotId; }
uint SelectParkingLotDialog::selectedVehicleId() const { return m_selectedVehicleId; }
