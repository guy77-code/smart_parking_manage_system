/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QStackedWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralwidget;
    QVBoxLayout *verticalLayout;
    QStackedWidget *stackedWidget;
    QWidget *loginPage;
    QVBoxLayout *verticalLayout_2;
    QLabel *label_title;
    QLineEdit *edit_username;
    QLineEdit *edit_password;
    QPushButton *btn_login;
    QHBoxLayout *horizontalLayout;
    QPushButton *btn_exit;
    QPushButton *btn_register;
    QLabel *label_status;
    QWidget *userPage;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName("MainWindow");
        MainWindow->resize(800, 600);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName("centralwidget");
        verticalLayout = new QVBoxLayout(centralwidget);
        verticalLayout->setObjectName("verticalLayout");
        stackedWidget = new QStackedWidget(centralwidget);
        stackedWidget->setObjectName("stackedWidget");
        loginPage = new QWidget();
        loginPage->setObjectName("loginPage");
        verticalLayout_2 = new QVBoxLayout(loginPage);
        verticalLayout_2->setObjectName("verticalLayout_2");
        label_title = new QLabel(loginPage);
        label_title->setObjectName("label_title");
        label_title->setStyleSheet(QString::fromUtf8("font-size: 16px; font-weight: bold; padding: 10px;"));
        label_title->setAlignment(Qt::AlignmentFlag::AlignCenter);

        verticalLayout_2->addWidget(label_title);

        edit_username = new QLineEdit(loginPage);
        edit_username->setObjectName("edit_username");
        edit_username->setStyleSheet(QString::fromUtf8("padding: 8px; font-size: 14px; font-family: \"Microsoft YaHei\", \"SimHei\", sans-serif;"));
        edit_username->setInputMethodHints(Qt::InputMethodHint::ImhPreferUppercase);

        verticalLayout_2->addWidget(edit_username);

        edit_password = new QLineEdit(loginPage);
        edit_password->setObjectName("edit_password");
        edit_password->setStyleSheet(QString::fromUtf8("padding: 8px; font-size: 14px; font-family: \"Microsoft YaHei\", \"SimHei\", sans-serif;"));
        edit_password->setInputMethodHints(Qt::InputMethodHint::ImhHiddenText|Qt::InputMethodHint::ImhNoPredictiveText);
        edit_password->setEchoMode(QLineEdit::EchoMode::Password);

        verticalLayout_2->addWidget(edit_password);

        btn_login = new QPushButton(loginPage);
        btn_login->setObjectName("btn_login");
        btn_login->setStyleSheet(QString::fromUtf8("padding: 10px; font-size: 14px; background-color: #4CAF50; color: white; border: none; border-radius: 4px;"));

        verticalLayout_2->addWidget(btn_login);

        horizontalLayout = new QHBoxLayout();
        horizontalLayout->setObjectName("horizontalLayout");
        btn_exit = new QPushButton(loginPage);
        btn_exit->setObjectName("btn_exit");
        btn_exit->setStyleSheet(QString::fromUtf8("padding: 8px; font-size: 14px; background-color: #f44336; color: white; border: none; border-radius: 4px;"));

        horizontalLayout->addWidget(btn_exit);

        btn_register = new QPushButton(loginPage);
        btn_register->setObjectName("btn_register");
        btn_register->setStyleSheet(QString::fromUtf8("padding: 8px; font-size: 14px; background-color: #2196F3; color: white; border: none; border-radius: 4px;"));

        horizontalLayout->addWidget(btn_register);


        verticalLayout_2->addLayout(horizontalLayout);

        label_status = new QLabel(loginPage);
        label_status->setObjectName("label_status");
        label_status->setStyleSheet(QString::fromUtf8("color: red; padding: 5px; font-size: 12px; font-family: \"Microsoft YaHei\", \"SimHei\", sans-serif;"));
        label_status->setAlignment(Qt::AlignmentFlag::AlignCenter);

        verticalLayout_2->addWidget(label_status);

        stackedWidget->addWidget(loginPage);
        userPage = new QWidget();
        userPage->setObjectName("userPage");
        stackedWidget->addWidget(userPage);

        verticalLayout->addWidget(stackedWidget);

        MainWindow->setCentralWidget(centralwidget);

        retranslateUi(MainWindow);

        stackedWidget->setCurrentIndex(0);


        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "\346\231\272\350\203\275\345\201\234\350\275\246\347\256\241\347\220\206\347\263\273\347\273\237", nullptr));
        label_title->setText(QCoreApplication::translate("MainWindow", "\346\231\272\350\203\275\345\201\234\350\275\246\347\256\241\347\220\206\347\263\273\347\273\237\347\231\273\345\275\225", nullptr));
        edit_username->setPlaceholderText(QCoreApplication::translate("MainWindow", "\350\257\267\350\276\223\345\205\245\346\211\213\346\234\272\345\217\267", nullptr));
        edit_password->setPlaceholderText(QCoreApplication::translate("MainWindow", "\350\257\267\350\276\223\345\205\245\345\257\206\347\240\201", nullptr));
        btn_login->setText(QCoreApplication::translate("MainWindow", "\347\231\273\345\275\225", nullptr));
        btn_exit->setText(QCoreApplication::translate("MainWindow", "\351\200\200\345\207\272\347\263\273\347\273\237", nullptr));
        btn_register->setText(QCoreApplication::translate("MainWindow", "\346\226\260\347\224\250\346\210\267\346\263\250\345\206\214", nullptr));
        label_status->setText(QString());
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
