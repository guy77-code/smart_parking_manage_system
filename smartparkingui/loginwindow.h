#ifndef LOGINWINDOWS_H
#define LOGINWINDOWS_H
#pragma once

#include <QDialog>
#include <QNetworkReply>
#include <QStackedWidget>
#include "userpage.h"
// 前向声明
class RegisterWindow;

QT_BEGIN_NAMESPACE
namespace Ui { class LoginWindow; }
QT_END_NAMESPACE

class LoginWindow : public QDialog {
    Q_OBJECT

public:
    explicit LoginWindow(QWidget *parent = nullptr);
    ~LoginWindow();

private slots:
    void onLoginButtonClicked();
    void onLoginReply(QNetworkReply *reply);
    void onExitButtonClicked();
    void onRegisterButtonClicked();
    void onBackToLogin();  // 从注册窗口返回登录窗口

private:
    Ui::LoginWindow *ui;
    RegisterWindow *registerWindow;  // 注册窗口指针
    QStackedWidget *stack;
    UserPage *userPage;
    void handleUserLogin(const QString &username, const QString &password);
};

#endif // LOGINWINDOWS_H
