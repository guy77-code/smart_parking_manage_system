#include "historywindow.h"
#include "ui_historywindow.h"
#include "networkmanager.h"
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonArray>

HistoryWindow::HistoryWindow(uint userId, QWidget *parent) :
    QWidget(parent),
    ui(new Ui::HistoryWindow),
    m_userId(userId)
{
    ui->setupUi(this);
    loadHistory();
}

HistoryWindow::~HistoryWindow()
{
    delete ui;
}

void HistoryWindow::loadHistory() {
    QNetworkReply *reply = NetworkManager::instance()->get(QUrl(QString("/api/user/history/%1").arg(m_userId)));
    connect(reply, &QNetworkReply::finished, [this, reply]() {
        QByteArray bytes = reply->readAll();
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            return;
        }
        QJsonDocument doc = QJsonDocument::fromJson(bytes);
        if (!doc.isArray()) return;
        QJsonArray arr = doc.array();

        ui->table_history->clear();
        ui->table_history->setColumnCount(6);
        ui->table_history->setHorizontalHeaderLabels({"记录ID","停车场","车牌","入场","出场","支付状态"});
        ui->table_history->setRowCount(arr.size());
        for (int i=0;i<arr.size();++i) {
            QJsonObject o = arr[i].toObject();
            ui->table_history->setItem(i,0, new QTableWidgetItem(QString::number(o.value("record_id").toInt())));
            ui->table_history->setItem(i,1, new QTableWidgetItem(o.value("lot_name").toString()));
            ui->table_history->setItem(i,2, new QTableWidgetItem(o.value("license_plate").toString()));
            ui->table_history->setItem(i,3, new QTableWidgetItem(o.value("entry_time").toString()));
            ui->table_history->setItem(i,4, new QTableWidgetItem(o.value("exit_time").toString()));
            ui->table_history->setItem(i,5, new QTableWidgetItem(o.value("payment_status").toInt() == 1 ? "已支付":"未支付"));
        }
        ui->table_history->resizeColumnsToContents();
    });
}
