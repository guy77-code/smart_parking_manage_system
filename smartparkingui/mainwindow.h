#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QNetworkReply>
#include <QStackedWidget>
#include "registerwindow.h"
#include "userpage.h"
#include"systemadminpage.h"

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onLoginButtonClicked();
    void onLoginReply(QNetworkReply *reply);
    void onExitButtonClicked();
    void onRegisterButtonClicked();
    void onBackToLogin();

private:
    Ui::MainWindow *ui;
    RegisterWindow *registerWindow = nullptr;
    UserPage *userPage = nullptr;
    SystemAdminPage *systemAdminPage = nullptr;
    void handleUserLogin(const QString &username, const QString &password);
    void handleAdminLogin(const QString &username, const QString &password);
};
#endif // MAINWINDOW_H
