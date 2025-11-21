/********************************************************************************
** Form generated from reading UI file 'registerwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_REGISTERWINDOW_H
#define UI_REGISTERWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QDialog>
#include <QtWidgets/QFormLayout>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QScrollArea>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_RegisterWindow
{
public:
    QVBoxLayout *verticalLayout;
    QLabel *label_title;
    QGroupBox *groupBox_user;
    QFormLayout *formLayout_user;
    QLabel *label_username;
    QLineEdit *edit_username;
    QLabel *label_password;
    QLineEdit *edit_password;
    QLabel *label_confirm_password;
    QLineEdit *edit_confirm_password;
    QLabel *label_phone;
    QLineEdit *edit_phone;
    QLabel *label_email;
    QLineEdit *edit_email;
    QLabel *label_real_name;
    QLineEdit *edit_real_name;
    QGroupBox *groupBox_vehicle;
    QVBoxLayout *vehicleMainLayout;
    QScrollArea *scrollArea_vehicles;
    QWidget *vehiclesContainer;
    QVBoxLayout *vehicleListLayout;
    QPushButton *btn_add_vehicle;
    QHBoxLayout *horizontalLayout_buttons;
    QPushButton *btn_register;
    QPushButton *btn_back;
    QLabel *label_status;

    void setupUi(QDialog *RegisterWindow)
    {
        if (RegisterWindow->objectName().isEmpty())
            RegisterWindow->setObjectName("RegisterWindow");
        RegisterWindow->resize(600, 750);
        RegisterWindow->setSizeGripEnabled(true);
        RegisterWindow->setMinimumSize(QSize(400, 500));
        verticalLayout = new QVBoxLayout(RegisterWindow);
        verticalLayout->setObjectName("verticalLayout");
        label_title = new QLabel(RegisterWindow);
        label_title->setObjectName("label_title");
        label_title->setAlignment(Qt::AlignCenter);
        label_title->setStyleSheet(QString::fromUtf8("font-size: 20px; font-weight: bold; padding: 10px;"));

        verticalLayout->addWidget(label_title);

        groupBox_user = new QGroupBox(RegisterWindow);
        groupBox_user->setObjectName("groupBox_user");
        QSizePolicy sizePolicy(QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Expanding);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(1);
        sizePolicy.setHeightForWidth(groupBox_user->sizePolicy().hasHeightForWidth());
        groupBox_user->setSizePolicy(sizePolicy);
        formLayout_user = new QFormLayout(groupBox_user);
        formLayout_user->setObjectName("formLayout_user");
        label_username = new QLabel(groupBox_user);
        label_username->setObjectName("label_username");

        formLayout_user->setWidget(0, QFormLayout::LabelRole, label_username);

        edit_username = new QLineEdit(groupBox_user);
        edit_username->setObjectName("edit_username");

        formLayout_user->setWidget(0, QFormLayout::FieldRole, edit_username);

        label_password = new QLabel(groupBox_user);
        label_password->setObjectName("label_password");

        formLayout_user->setWidget(1, QFormLayout::LabelRole, label_password);

        edit_password = new QLineEdit(groupBox_user);
        edit_password->setObjectName("edit_password");
        edit_password->setEchoMode(QLineEdit::Password);

        formLayout_user->setWidget(1, QFormLayout::FieldRole, edit_password);

        label_confirm_password = new QLabel(groupBox_user);
        label_confirm_password->setObjectName("label_confirm_password");

        formLayout_user->setWidget(2, QFormLayout::LabelRole, label_confirm_password);

        edit_confirm_password = new QLineEdit(groupBox_user);
        edit_confirm_password->setObjectName("edit_confirm_password");
        edit_confirm_password->setEchoMode(QLineEdit::Password);

        formLayout_user->setWidget(2, QFormLayout::FieldRole, edit_confirm_password);

        label_phone = new QLabel(groupBox_user);
        label_phone->setObjectName("label_phone");

        formLayout_user->setWidget(3, QFormLayout::LabelRole, label_phone);

        edit_phone = new QLineEdit(groupBox_user);
        edit_phone->setObjectName("edit_phone");

        formLayout_user->setWidget(3, QFormLayout::FieldRole, edit_phone);

        label_email = new QLabel(groupBox_user);
        label_email->setObjectName("label_email");

        formLayout_user->setWidget(4, QFormLayout::LabelRole, label_email);

        edit_email = new QLineEdit(groupBox_user);
        edit_email->setObjectName("edit_email");

        formLayout_user->setWidget(4, QFormLayout::FieldRole, edit_email);

        label_real_name = new QLabel(groupBox_user);
        label_real_name->setObjectName("label_real_name");

        formLayout_user->setWidget(5, QFormLayout::LabelRole, label_real_name);

        edit_real_name = new QLineEdit(groupBox_user);
        edit_real_name->setObjectName("edit_real_name");

        formLayout_user->setWidget(5, QFormLayout::FieldRole, edit_real_name);


        verticalLayout->addWidget(groupBox_user);

        groupBox_vehicle = new QGroupBox(RegisterWindow);
        groupBox_vehicle->setObjectName("groupBox_vehicle");
        QSizePolicy sizePolicy1(QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Expanding);
        sizePolicy1.setHorizontalStretch(0);
        sizePolicy1.setVerticalStretch(2);
        sizePolicy1.setHeightForWidth(groupBox_vehicle->sizePolicy().hasHeightForWidth());
        groupBox_vehicle->setSizePolicy(sizePolicy1);
        vehicleMainLayout = new QVBoxLayout(groupBox_vehicle);
        vehicleMainLayout->setObjectName("vehicleMainLayout");
        scrollArea_vehicles = new QScrollArea(groupBox_vehicle);
        scrollArea_vehicles->setObjectName("scrollArea_vehicles");
        scrollArea_vehicles->setWidgetResizable(true);
        vehiclesContainer = new QWidget();
        vehiclesContainer->setObjectName("vehiclesContainer");
        vehicleListLayout = new QVBoxLayout(vehiclesContainer);
        vehicleListLayout->setObjectName("vehicleListLayout");
        scrollArea_vehicles->setWidget(vehiclesContainer);

        vehicleMainLayout->addWidget(scrollArea_vehicles);

        btn_add_vehicle = new QPushButton(groupBox_vehicle);
        btn_add_vehicle->setObjectName("btn_add_vehicle");

        vehicleMainLayout->addWidget(btn_add_vehicle);

        vehicleMainLayout->setStretch(0, 1);

        verticalLayout->addWidget(groupBox_vehicle);

        horizontalLayout_buttons = new QHBoxLayout();
        horizontalLayout_buttons->setObjectName("horizontalLayout_buttons");
        btn_register = new QPushButton(RegisterWindow);
        btn_register->setObjectName("btn_register");

        horizontalLayout_buttons->addWidget(btn_register);

        btn_back = new QPushButton(RegisterWindow);
        btn_back->setObjectName("btn_back");

        horizontalLayout_buttons->addWidget(btn_back);


        verticalLayout->addLayout(horizontalLayout_buttons);

        label_status = new QLabel(RegisterWindow);
        label_status->setObjectName("label_status");
        label_status->setAlignment(Qt::AlignCenter);
        label_status->setStyleSheet(QString::fromUtf8("color: red; padding: 5px; font-size: 12px;"));

        verticalLayout->addWidget(label_status);

        verticalLayout->setStretch(1, 1);
        verticalLayout->setStretch(2, 2);

        retranslateUi(RegisterWindow);

        QMetaObject::connectSlotsByName(RegisterWindow);
    } // setupUi

    void retranslateUi(QDialog *RegisterWindow)
    {
        RegisterWindow->setWindowTitle(QCoreApplication::translate("RegisterWindow", "\347\224\250\346\210\267\346\263\250\345\206\214", nullptr));
        label_title->setText(QCoreApplication::translate("RegisterWindow", "\346\226\260\347\224\250\346\210\267\346\263\250\345\206\214", nullptr));
        groupBox_user->setTitle(QCoreApplication::translate("RegisterWindow", "\347\224\250\346\210\267\344\277\241\346\201\257", nullptr));
        label_username->setText(QCoreApplication::translate("RegisterWindow", "\347\224\250\346\210\267\345\220\215*", nullptr));
        edit_username->setPlaceholderText(QCoreApplication::translate("RegisterWindow", "3-50\344\270\252\345\255\227\347\254\246", nullptr));
        label_password->setText(QCoreApplication::translate("RegisterWindow", "\345\257\206\347\240\201*", nullptr));
        edit_password->setPlaceholderText(QCoreApplication::translate("RegisterWindow", "\350\207\263\345\260\2216\344\270\252\345\255\227\347\254\246", nullptr));
        label_confirm_password->setText(QCoreApplication::translate("RegisterWindow", "\347\241\256\350\256\244\345\257\206\347\240\201*", nullptr));
        edit_confirm_password->setPlaceholderText(QCoreApplication::translate("RegisterWindow", "\345\206\215\346\254\241\350\276\223\345\205\245\345\257\206\347\240\201", nullptr));
        label_phone->setText(QCoreApplication::translate("RegisterWindow", "\346\211\213\346\234\272\345\217\267*", nullptr));
        edit_phone->setPlaceholderText(QCoreApplication::translate("RegisterWindow", "11\344\275\215\346\211\213\346\234\272\345\217\267\347\240\201", nullptr));
        label_email->setText(QCoreApplication::translate("RegisterWindow", "\351\202\256\347\256\261", nullptr));
        edit_email->setPlaceholderText(QCoreApplication::translate("RegisterWindow", "\345\217\257\351\200\211", nullptr));
        label_real_name->setText(QCoreApplication::translate("RegisterWindow", "\347\234\237\345\256\236\345\247\223\345\220\215", nullptr));
        edit_real_name->setPlaceholderText(QCoreApplication::translate("RegisterWindow", "\345\217\257\351\200\211", nullptr));
        groupBox_vehicle->setTitle(QCoreApplication::translate("RegisterWindow", "\350\275\246\350\276\206\344\277\241\346\201\257\357\274\210\345\217\257\346\267\273\345\212\240\345\244\232\350\276\206\357\274\211", nullptr));
        btn_add_vehicle->setText(QCoreApplication::translate("RegisterWindow", "\346\267\273\345\212\240\350\275\246\350\276\206", nullptr));
        btn_register->setText(QCoreApplication::translate("RegisterWindow", "\346\263\250\345\206\214", nullptr));
        btn_back->setText(QCoreApplication::translate("RegisterWindow", "\350\277\224\345\233\236\347\231\273\345\275\225", nullptr));
        label_status->setText(QString());
    } // retranslateUi

};

namespace Ui {
    class RegisterWindow: public Ui_RegisterWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_REGISTERWINDOW_H
