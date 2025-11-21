/********************************************************************************
** Form generated from reading UI file 'selectparkinglotdialog.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_SELECTPARKINGLOTDIALOG_H
#define UI_SELECTPARKINGLOTDIALOG_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QTableWidget>
#include <QtWidgets/QVBoxLayout>

QT_BEGIN_NAMESPACE

class Ui_SelectParkingLotDialog
{
public:
    QVBoxLayout *verticalLayout;
    QLabel *label;
    QTableWidget *table_lots;
    QHBoxLayout *hLayout;
    QComboBox *combo_vehicles;
    QSpacerItem *hSpacer;
    QPushButton *btn_ok;
    QPushButton *btn_cancel;

    void setupUi(QDialog *SelectParkingLotDialog)
    {
        if (SelectParkingLotDialog->objectName().isEmpty())
            SelectParkingLotDialog->setObjectName("SelectParkingLotDialog");
        SelectParkingLotDialog->setMinimumSize(QSize(520, 420));
        verticalLayout = new QVBoxLayout(SelectParkingLotDialog);
        verticalLayout->setObjectName("verticalLayout");
        label = new QLabel(SelectParkingLotDialog);
        label->setObjectName("label");
        label->setAlignment(Qt::AlignCenter);

        verticalLayout->addWidget(label);

        table_lots = new QTableWidget(SelectParkingLotDialog);
        if (table_lots->columnCount() < 3)
            table_lots->setColumnCount(3);
        QTableWidgetItem *__qtablewidgetitem = new QTableWidgetItem();
        table_lots->setHorizontalHeaderItem(0, __qtablewidgetitem);
        QTableWidgetItem *__qtablewidgetitem1 = new QTableWidgetItem();
        table_lots->setHorizontalHeaderItem(1, __qtablewidgetitem1);
        QTableWidgetItem *__qtablewidgetitem2 = new QTableWidgetItem();
        table_lots->setHorizontalHeaderItem(2, __qtablewidgetitem2);
        table_lots->setObjectName("table_lots");
        table_lots->setColumnCount(3);

        verticalLayout->addWidget(table_lots);

        hLayout = new QHBoxLayout();
        hLayout->setObjectName("hLayout");
        combo_vehicles = new QComboBox(SelectParkingLotDialog);
        combo_vehicles->setObjectName("combo_vehicles");

        hLayout->addWidget(combo_vehicles);

        hSpacer = new QSpacerItem(0, 0, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        hLayout->addItem(hSpacer);

        btn_ok = new QPushButton(SelectParkingLotDialog);
        btn_ok->setObjectName("btn_ok");

        hLayout->addWidget(btn_ok);

        btn_cancel = new QPushButton(SelectParkingLotDialog);
        btn_cancel->setObjectName("btn_cancel");

        hLayout->addWidget(btn_cancel);


        verticalLayout->addLayout(hLayout);


        retranslateUi(SelectParkingLotDialog);

        QMetaObject::connectSlotsByName(SelectParkingLotDialog);
    } // setupUi

    void retranslateUi(QDialog *SelectParkingLotDialog)
    {
        label->setText(QCoreApplication::translate("SelectParkingLotDialog", "\350\257\267\351\200\211\346\213\251\345\201\234\350\275\246\345\234\272\344\270\216\350\275\246\350\276\206", nullptr));
        QTableWidgetItem *___qtablewidgetitem = table_lots->horizontalHeaderItem(0);
        ___qtablewidgetitem->setText(QCoreApplication::translate("SelectParkingLotDialog", "\345\201\234\350\275\246\345\234\272ID", nullptr));
        QTableWidgetItem *___qtablewidgetitem1 = table_lots->horizontalHeaderItem(1);
        ___qtablewidgetitem1->setText(QCoreApplication::translate("SelectParkingLotDialog", "\345\220\215\347\247\260", nullptr));
        QTableWidgetItem *___qtablewidgetitem2 = table_lots->horizontalHeaderItem(2);
        ___qtablewidgetitem2->setText(QCoreApplication::translate("SelectParkingLotDialog", "\345\234\260\345\235\200", nullptr));
        btn_ok->setText(QCoreApplication::translate("SelectParkingLotDialog", "\347\241\256\345\256\232\345\201\234\350\275\246", nullptr));
        btn_cancel->setText(QCoreApplication::translate("SelectParkingLotDialog", "\345\217\226\346\266\210", nullptr));
        (void)SelectParkingLotDialog;
    } // retranslateUi

};

namespace Ui {
    class SelectParkingLotDialog: public Ui_SelectParkingLotDialog {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_SELECTPARKINGLOTDIALOG_H
