/********************************************************************************
** Form generated from reading UI file 'bookingwindow.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_BOOKINGWINDOW_H
#define UI_BOOKINGWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDateTimeEdit>
#include <QtWidgets/QDialog>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QVBoxLayout>

QT_BEGIN_NAMESPACE

class Ui_BookingWindow
{
public:
    QVBoxLayout *verticalLayout;
    QLabel *label_status;
    QPushButton *btn_refresh;
    QListWidget *list_lots;
    QComboBox *combo_space_type;
    QHBoxLayout *timeLayout;
    QLabel *label_start;
    QDateTimeEdit *datetime_start;
    QLabel *label_end;
    QDateTimeEdit *datetime_end;
    QHBoxLayout *hboxLayout;
    QPushButton *btn_confirm;
    QPushButton *btn_cancel;

    void setupUi(QDialog *BookingWindow)
    {
        if (BookingWindow->objectName().isEmpty())
            BookingWindow->setObjectName("BookingWindow");
        BookingWindow->resize(1100, 750);
        QSizePolicy sizePolicy(QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Expanding);
        sizePolicy.setHorizontalStretch(0);
        sizePolicy.setVerticalStretch(0);
        sizePolicy.setHeightForWidth(BookingWindow->sizePolicy().hasHeightForWidth());
        BookingWindow->setSizePolicy(sizePolicy);
        verticalLayout = new QVBoxLayout(BookingWindow);
        verticalLayout->setObjectName("verticalLayout");
        label_status = new QLabel(BookingWindow);
        label_status->setObjectName("label_status");

        verticalLayout->addWidget(label_status);

        btn_refresh = new QPushButton(BookingWindow);
        btn_refresh->setObjectName("btn_refresh");

        verticalLayout->addWidget(btn_refresh);

        list_lots = new QListWidget(BookingWindow);
        list_lots->setObjectName("list_lots");

        verticalLayout->addWidget(list_lots);

        combo_space_type = new QComboBox(BookingWindow);
        combo_space_type->setObjectName("combo_space_type");

        verticalLayout->addWidget(combo_space_type);

        timeLayout = new QHBoxLayout();
        timeLayout->setObjectName("timeLayout");
        label_start = new QLabel(BookingWindow);
        label_start->setObjectName("label_start");

        timeLayout->addWidget(label_start);

        datetime_start = new QDateTimeEdit(BookingWindow);
        datetime_start->setObjectName("datetime_start");

        timeLayout->addWidget(datetime_start);

        label_end = new QLabel(BookingWindow);
        label_end->setObjectName("label_end");

        timeLayout->addWidget(label_end);

        datetime_end = new QDateTimeEdit(BookingWindow);
        datetime_end->setObjectName("datetime_end");

        timeLayout->addWidget(datetime_end);


        verticalLayout->addLayout(timeLayout);

        hboxLayout = new QHBoxLayout();
        hboxLayout->setObjectName("hboxLayout");
        btn_confirm = new QPushButton(BookingWindow);
        btn_confirm->setObjectName("btn_confirm");

        hboxLayout->addWidget(btn_confirm);

        btn_cancel = new QPushButton(BookingWindow);
        btn_cancel->setObjectName("btn_cancel");

        hboxLayout->addWidget(btn_cancel);


        verticalLayout->addLayout(hboxLayout);


        retranslateUi(BookingWindow);

        QMetaObject::connectSlotsByName(BookingWindow);
    } // setupUi

    void retranslateUi(QDialog *BookingWindow)
    {
        BookingWindow->setWindowTitle(QCoreApplication::translate("BookingWindow", "\351\242\204\350\256\242\350\275\246\344\275\215", nullptr));
        label_status->setText(QCoreApplication::translate("BookingWindow", "\345\212\240\350\275\275\344\270\255...", nullptr));
        btn_refresh->setText(QCoreApplication::translate("BookingWindow", "\345\210\267\346\226\260\351\231\204\350\277\221\345\201\234\350\275\246\345\234\272", nullptr));
        combo_space_type->setPlaceholderText(QCoreApplication::translate("BookingWindow", "\351\200\211\346\213\251\350\275\246\344\275\215\347\261\273\345\236\213", nullptr));
        label_start->setText(QCoreApplication::translate("BookingWindow", "\345\274\200\345\247\213\346\227\266\351\227\264\357\274\232", nullptr));
        label_end->setText(QCoreApplication::translate("BookingWindow", "\347\273\223\346\235\237\346\227\266\351\227\264\357\274\232", nullptr));
        btn_confirm->setText(QCoreApplication::translate("BookingWindow", "\347\241\256\350\256\244\351\242\204\350\256\242", nullptr));
        btn_cancel->setText(QCoreApplication::translate("BookingWindow", "\345\217\226\346\266\210", nullptr));
    } // retranslateUi

};

namespace Ui {
    class BookingWindow: public Ui_BookingWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_BOOKINGWINDOW_H
