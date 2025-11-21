#include "systemadminpage.h"
#include "ui_systemadminpage.h"
#include <QJsonDocument>
#include <QInputDialog>
#include <QDateTime>
#include <QHeaderView>

SystemAdminPage::SystemAdminPage(QWidget *parent)
    : QWidget(parent)
    , ui(new Ui::SystemAdminPage)
    , net(NetworkManager::instance())
{
    ui->setupUi(this);
    setWindowTitle("系统管理员后台 - 智能停车系统");
    resize(1200, 800);

    // 表格设置
    ui->table_parkingLots->setEditTriggers(QAbstractItemView::NoEditTriggers);
    ui->table_parkingLots->setSelectionBehavior(QAbstractItemView::SelectRows);
    ui->table_parkingLots->setSelectionMode(QAbstractItemView::SingleSelection);
    ui->table_parkingLots->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);

    connect(ui->btn_refresh, &QPushButton::clicked, this, &SystemAdminPage::loadParkingLots);
    connect(ui->btn_add, &QPushButton::clicked, this, &SystemAdminPage::onAddParkingLot);
    connect(ui->btn_delete, &QPushButton::clicked, this, &SystemAdminPage::onDeleteParkingLot);
    connect(ui->btn_queryViolation, &QPushButton::clicked, this, &SystemAdminPage::onQueryViolationData);
    connect(ui->btn_logout, &QPushButton::clicked, this, &SystemAdminPage::onLogout);

    // 初始加载
    loadParkingLots();
}

SystemAdminPage::~SystemAdminPage()
{
    delete ui;
}

void SystemAdminPage::loadParkingLots()
{
    QNetworkReply *reply = net->get(QUrl("/api/v1/admin/parking-lots"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        QByteArray data = reply->readAll();
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            showError("加载停车场失败: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(data);
        if (!doc.isObject()) {
            showError("返回数据格式错误");
            return;
        }

        QJsonArray arr = doc.object()["data"].toArray();
        populateParkingLots(arr);
    });
}

void SystemAdminPage::populateParkingLots(const QJsonArray &data)
{
    ui->table_parkingLots->clearContents();
    ui->table_parkingLots->setRowCount(data.size());
    ui->table_parkingLots->setColumnCount(5);
    QStringList headers = {"ID", "地点", "收费标准(元/小时)", "车位数量", "创建时间"};
    ui->table_parkingLots->setHorizontalHeaderLabels(headers);

    for (int i = 0; i < data.size(); ++i) {
        QJsonObject obj = data[i].toObject();
        ui->table_parkingLots->setItem(i, 0, new QTableWidgetItem(QString::number(obj["id"].toInt())));
        ui->table_parkingLots->setItem(i, 1, new QTableWidgetItem(obj["location"].toString()));
        ui->table_parkingLots->setItem(i, 2, new QTableWidgetItem(QString::number(obj["rate"].toDouble())));
        ui->table_parkingLots->setItem(i, 3, new QTableWidgetItem(QString::number(obj["total_spaces"].toInt())));
        ui->table_parkingLots->setItem(i, 4, new QTableWidgetItem(obj["created_at"].toString()));
    }
}

void SystemAdminPage::onAddParkingLot()
{
    bool ok;
    QString location = QInputDialog::getText(this, "添加停车场", "请输入停车场位置：", QLineEdit::Normal, "", &ok);
    if (!ok || location.isEmpty()) return;

    double rate = QInputDialog::getDouble(this, "添加停车场", "请输入收费标准（元/小时）：", 5.0, 0, 100, 2, &ok);
    if (!ok) return;

    int spaces = QInputDialog::getInt(this, "添加停车场", "请输入车位数量：", 50, 1, 1000, 1, &ok);
    if (!ok) return;

    QJsonObject obj;
    obj["location"] = location;
    obj["rate"] = rate;
    obj["total_spaces"] = spaces;

    QNetworkReply *reply = net->postJson(QUrl("/api/v1/admin/parking-lots/add"), obj);
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        QByteArray data = reply->readAll();
        reply->deleteLater();

        if (reply->error() == QNetworkReply::NoError) {
            QMessageBox::information(this, "成功", "添加停车场成功！");
            loadParkingLots();
        } else {
            showError("添加失败: " + reply->errorString());
        }
    });
}

void SystemAdminPage::onDeleteParkingLot()
{
    auto selected = ui->table_parkingLots->currentRow();
    if (selected < 0) {
        QMessageBox::warning(this, "提示", "请先选择要删除的停车场！");
        return;
    }

    QString lotId = ui->table_parkingLots->item(selected, 0)->text();
    if (QMessageBox::question(this, "确认删除", "确定要删除停车场 ID " + lotId + " 吗？") != QMessageBox::Yes)
        return;

    QNetworkReply *reply = net->deleteRequest(QUrl("/api/v1/admin/parking-lots/" + lotId));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        reply->deleteLater();
        if (reply->error() == QNetworkReply::NoError) {
            QMessageBox::information(this, "成功", "删除成功！");
            loadParkingLots();
        } else {
            showError("删除失败: " + reply->errorString());
        }
    });
}

void SystemAdminPage::onQueryViolationData()
{
    QNetworkReply *reply = net->get(QUrl("/api/v1/admin/violations/statistics"));
    connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        QByteArray response = reply->readAll();
        reply->deleteLater();

        if (reply->error() != QNetworkReply::NoError) {
            showError("查询失败: " + reply->errorString());
            return;
        }

        QJsonDocument doc = QJsonDocument::fromJson(response);
        QJsonObject data = doc.object()["data"].toObject();

        QString result = QString("违规停车总数：%1\n已处理：%2\n总罚款：%3 元")
                             .arg(data["total_violations"].toInt())
                             .arg(data["processed_count"].toInt())
                             .arg(data["total_fines"].toDouble());
        QMessageBox::information(this, "违规数据统计", result);
    });
}

void SystemAdminPage::onLogout()
{
    if (QMessageBox::question(this, "退出登录", "确定退出当前账户？") == QMessageBox::Yes)
        emit requestLogout();
}

void SystemAdminPage::showError(const QString &msg)
{
    QMessageBox::critical(this, "错误", msg);
}
