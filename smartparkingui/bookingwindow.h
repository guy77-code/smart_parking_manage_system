#ifndef BOOKINGWINDOW_H
#define BOOKINGWINDOW_H

#include <QDialog>
#include <QNetworkReply>
#include <QDateTime>

namespace Ui {
class BookingWindow;
}

class BookingWindow : public QDialog
{
    Q_OBJECT

public:
    explicit BookingWindow(uint userId, QWidget *parent = nullptr);
    ~BookingWindow();

private slots:
    void loadNearbyParkingLots();   // 加载附近停车场
    void onParkingLotsReply();      // 处理停车场数据返回
    void onLotSelected();           // 用户选择停车场
    void onSpaceTypesReply();       // 加载车位类型
    void onConfirmBooking();        // 确认预订
    void onBookingReply();          // 处理预订返回
    void showMessage(const QString &title, const QString &msg);

private:
    Ui::BookingWindow *ui;
    uint m_userId;
    uint m_selectedLotId;
};

#endif // BOOKINGWINDOW_H
