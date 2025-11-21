#ifndef REGISTERWINDOW_H
#define REGISTERWINDOW_H

#include <QDialog>
#include <QNetworkReply>
#include <QLineEdit>
#include <QFormLayout>

namespace Ui {
class RegisterWindow;
}

struct VehicleForm {
    QLineEdit *licensePlate;
    QLineEdit *brand;
    QLineEdit *model;
    QLineEdit *color;
};

class RegisterWindow : public QDialog {
    Q_OBJECT

public:
    explicit RegisterWindow(QWidget *parent = nullptr);
    ~RegisterWindow();

signals:
    void backToLogin();
    void registerSuccess();

private slots:
    void onRegisterButtonClicked();
    void onBackButtonClicked();
    void onRegisterReply(QNetworkReply *reply);
    void onAddVehicleClicked();

private:
    Ui::RegisterWindow *ui;
    void handleUserRegister();
    bool validateInput();

    QVector<VehicleForm> vehicleForms;   // 多辆车
};

#endif // REGISTERWINDOW_H
