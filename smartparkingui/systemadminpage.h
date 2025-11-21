#ifndef SYSTEMADMINPAGE_H
#define SYSTEMADMINPAGE_H

#include <QWidget>
#include <QTableWidget>
#include <QPushButton>
#include <QVBoxLayout>
#include <QMessageBox>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkReply>
#include "networkmanager.h"

namespace Ui {
class SystemAdminPage;
}

class SystemAdminPage : public QWidget
{
    Q_OBJECT

public:
    explicit SystemAdminPage(QWidget *parent = nullptr);
    ~SystemAdminPage();

signals:
    void requestLogout();  // 退出信号

private slots:
    void loadParkingLots();          // 加载停车场数据
    void onAddParkingLot();          // 添加停车场
    void onDeleteParkingLot();       // 删除选中停车场
    void onQueryViolationData();     // 查询违规停车数据
    void onLogout();                 // 退出

private:
    Ui::SystemAdminPage *ui;
    NetworkManager *net;

    void populateParkingLots(const QJsonArray &data);
    void showError(const QString &msg);
};

#endif // SYSTEMADMINPAGE_H
