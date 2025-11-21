/********************************************************************************
** Form generated from reading UI file 'addparkingdialog.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_ADDPARKINGDIALOG_H
#define UI_ADDPARKINGDIALOG_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QDialog>
#include <QtWidgets/QFormLayout>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QVBoxLayout>

QT_BEGIN_NAMESPACE

class Ui_AddParkingDialog
{
public:
    QVBoxLayout *verticalLayout;
    QFormLayout *formLayout;
    QLabel *label_name;
    QLineEdit *edit_name;
    QLabel *label_location;
    QLineEdit *edit_location;
    QLabel *label_rate;
    QLineEdit *edit_rate;
    QLabel *label_spaces;
    QSpinBox *spin_spaces;
    QHBoxLayout *buttonLayout;
    QSpacerItem *spacerLeft;
    QPushButton *btn_cancel;
    QPushButton *btn_add;

    void setupUi(QDialog *AddParkingDialog)
    {
        if (AddParkingDialog->objectName().isEmpty())
            AddParkingDialog->setObjectName("AddParkingDialog");
        AddParkingDialog->resize(600, 480);
        verticalLayout = new QVBoxLayout(AddParkingDialog);
        verticalLayout->setObjectName("verticalLayout");
        formLayout = new QFormLayout();
        formLayout->setObjectName("formLayout");
        label_name = new QLabel(AddParkingDialog);
        label_name->setObjectName("label_name");

        formLayout->setWidget(0, QFormLayout::LabelRole, label_name);

        edit_name = new QLineEdit(AddParkingDialog);
        edit_name->setObjectName("edit_name");

        formLayout->setWidget(0, QFormLayout::FieldRole, edit_name);

        label_location = new QLabel(AddParkingDialog);
        label_location->setObjectName("label_location");

        formLayout->setWidget(1, QFormLayout::LabelRole, label_location);

        edit_location = new QLineEdit(AddParkingDialog);
        edit_location->setObjectName("edit_location");

        formLayout->setWidget(1, QFormLayout::FieldRole, edit_location);

        label_rate = new QLabel(AddParkingDialog);
        label_rate->setObjectName("label_rate");

        formLayout->setWidget(2, QFormLayout::LabelRole, label_rate);

        edit_rate = new QLineEdit(AddParkingDialog);
        edit_rate->setObjectName("edit_rate");

        formLayout->setWidget(2, QFormLayout::FieldRole, edit_rate);

        label_spaces = new QLabel(AddParkingDialog);
        label_spaces->setObjectName("label_spaces");

        formLayout->setWidget(3, QFormLayout::LabelRole, label_spaces);

        spin_spaces = new QSpinBox(AddParkingDialog);
        spin_spaces->setObjectName("spin_spaces");
        spin_spaces->setMinimum(1);
        spin_spaces->setMaximum(100000);
        spin_spaces->setValue(100);

        formLayout->setWidget(3, QFormLayout::FieldRole, spin_spaces);


        verticalLayout->addLayout(formLayout);

        buttonLayout = new QHBoxLayout();
        buttonLayout->setObjectName("buttonLayout");
        spacerLeft = new QSpacerItem(0, 0, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        buttonLayout->addItem(spacerLeft);

        btn_cancel = new QPushButton(AddParkingDialog);
        btn_cancel->setObjectName("btn_cancel");

        buttonLayout->addWidget(btn_cancel);

        btn_add = new QPushButton(AddParkingDialog);
        btn_add->setObjectName("btn_add");

        buttonLayout->addWidget(btn_add);


        verticalLayout->addLayout(buttonLayout);


        retranslateUi(AddParkingDialog);

        QMetaObject::connectSlotsByName(AddParkingDialog);
    } // setupUi

    void retranslateUi(QDialog *AddParkingDialog)
    {
        AddParkingDialog->setWindowTitle(QCoreApplication::translate("AddParkingDialog", "\346\267\273\345\212\240\345\201\234\350\275\246\345\234\272", nullptr));
        label_name->setText(QCoreApplication::translate("AddParkingDialog", "\345\220\215\347\247\260\357\274\232", nullptr));
        label_location->setText(QCoreApplication::translate("AddParkingDialog", "\345\234\260\347\202\271\357\274\232", nullptr));
        label_rate->setText(QCoreApplication::translate("AddParkingDialog", "\346\224\266\350\264\271\346\240\207\345\207\206\357\274\232", nullptr));
        label_spaces->setText(QCoreApplication::translate("AddParkingDialog", "\350\275\246\344\275\215\346\225\260\351\207\217\357\274\232", nullptr));
        btn_cancel->setText(QCoreApplication::translate("AddParkingDialog", "\345\217\226\346\266\210", nullptr));
        btn_add->setText(QCoreApplication::translate("AddParkingDialog", "\346\267\273\345\212\240", nullptr));
    } // retranslateUi

};

namespace Ui {
    class AddParkingDialog: public Ui_AddParkingDialog {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_ADDPARKINGDIALOG_H
