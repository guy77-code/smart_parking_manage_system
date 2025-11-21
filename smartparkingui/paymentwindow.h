#ifndef PAYMENTWINDOW_H
#define PAYMENTWINDOW_H

#include <QWidget>

namespace Ui {
class PaymentWindow;
}

class PaymentWindow : public QWidget
{
    Q_OBJECT

public:
    explicit PaymentWindow(uint orderId, QWidget *parent = nullptr);
    ~PaymentWindow();

signals:
    void paymentSucceeded();

private slots:
    void onPayClicked();
    void onCancelClicked();

private:
    Ui::PaymentWindow *ui;
    uint m_orderId;
    void loadOrderInfo();
};

#endif // PAYMENTWINDOW_H
