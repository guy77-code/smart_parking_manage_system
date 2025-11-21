#ifndef USERPAGE_H
#define USERPAGE_H

#include <QWidget>
#include <QJsonObject>
#include <QTimer>

namespace Ui {
class UserPage;
}

class UserPage : public QWidget
{
    Q_OBJECT

public:
    explicit UserPage(uint userId, QWidget *parent = nullptr);
    ~UserPage();

    void refreshStatus();

signals:
    // ✅ 发射退出信号
    void requestLogout();


private slots:
    void onBtnPark();
    void onBtnLeave();
    void onBtnReserve();
    void onBtnViewHistory();
    void handleRefreshClicked();

    void onBtnLogoutClicked(); // ✅ 新增

    // network callbacks
    void onUserStatusReply();
    void onEnterReply();
    void onExitReply();
    void onGenerateViolationReply();

private:
    Ui::UserPage *ui;
    uint m_userId;
    QTimer m_autoRefreshTimer;

    void showSelectParkingDialog();
    void openPaymentWindow(uint orderId);
    void showMessage(const QString &title, const QString &msg);
};

#endif // USERPAGE_H
