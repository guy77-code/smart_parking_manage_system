/********************************************************************************
** Form generated from reading UI file 'paymentwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_PAYMENTWINDOW_H
#define UI_PAYMENTWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_PaymentWindow
{
public:
    QVBoxLayout *verticalLayout;
    QLabel *label_title;
    QLabel *label_info;
    QHBoxLayout *hLayout;
    QPushButton *btn_pay;
    QPushButton *btn_cancel;

    void setupUi(QWidget *PaymentWindow)
    {
        if (PaymentWindow->objectName().isEmpty())
            PaymentWindow->setObjectName("PaymentWindow");
        PaymentWindow->setMinimumSize(QSize(480, 320));
        verticalLayout = new QVBoxLayout(PaymentWindow);
        verticalLayout->setObjectName("verticalLayout");
        label_title = new QLabel(PaymentWindow);
        label_title->setObjectName("label_title");
        label_title->setAlignment(Qt::AlignCenter);
        QFont font;
        font.setPointSize(12);
        font.setBold(true);
        label_title->setFont(font);

        verticalLayout->addWidget(label_title);

        label_info = new QLabel(PaymentWindow);
        label_info->setObjectName("label_info");

        verticalLayout->addWidget(label_info);

        hLayout = new QHBoxLayout();
        hLayout->setObjectName("hLayout");
        btn_pay = new QPushButton(PaymentWindow);
        btn_pay->setObjectName("btn_pay");

        hLayout->addWidget(btn_pay);

        btn_cancel = new QPushButton(PaymentWindow);
        btn_cancel->setObjectName("btn_cancel");

        hLayout->addWidget(btn_cancel);


        verticalLayout->addLayout(hLayout);


        retranslateUi(PaymentWindow);

        QMetaObject::connectSlotsByName(PaymentWindow);
    } // setupUi

    void retranslateUi(QWidget *PaymentWindow)
    {
        label_title->setText(QCoreApplication::translate("PaymentWindow", "\346\224\257\344\273\230\350\256\242\345\215\225", nullptr));
        label_info->setText(QCoreApplication::translate("PaymentWindow", "\345\212\240\350\275\275\350\256\242\345\215\225\344\277\241\346\201\257\342\200\246", nullptr));
        btn_pay->setText(QCoreApplication::translate("PaymentWindow", "\346\250\241\346\213\237\346\224\257\344\273\230\357\274\210\346\210\220\345\212\237\357\274\211", nullptr));
        btn_cancel->setText(QCoreApplication::translate("PaymentWindow", "\345\217\226\346\266\210", nullptr));
        (void)PaymentWindow;
    } // retranslateUi

};

namespace Ui {
    class PaymentWindow: public Ui_PaymentWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_PAYMENTWINDOW_H
