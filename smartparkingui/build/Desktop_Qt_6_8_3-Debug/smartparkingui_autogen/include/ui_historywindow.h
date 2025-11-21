/********************************************************************************
** Form generated from reading UI file 'historywindow.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_HISTORYWINDOW_H
#define UI_HISTORYWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QTableWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_HistoryWindow
{
public:
    QVBoxLayout *verticalLayout;
    QLabel *label_title;
    QTableWidget *table_history;

    void setupUi(QWidget *HistoryWindow)
    {
        if (HistoryWindow->objectName().isEmpty())
            HistoryWindow->setObjectName("HistoryWindow");
        HistoryWindow->setMinimumSize(QSize(760, 480));
        verticalLayout = new QVBoxLayout(HistoryWindow);
        verticalLayout->setObjectName("verticalLayout");
        label_title = new QLabel(HistoryWindow);
        label_title->setObjectName("label_title");
        label_title->setAlignment(Qt::AlignCenter);

        verticalLayout->addWidget(label_title);

        table_history = new QTableWidget(HistoryWindow);
        table_history->setObjectName("table_history");

        verticalLayout->addWidget(table_history);


        retranslateUi(HistoryWindow);

        QMetaObject::connectSlotsByName(HistoryWindow);
    } // setupUi

    void retranslateUi(QWidget *HistoryWindow)
    {
        label_title->setText(QCoreApplication::translate("HistoryWindow", "\345\216\206\345\217\262\345\201\234\350\275\246\344\270\216\346\224\257\344\273\230\350\256\260\345\275\225", nullptr));
        (void)HistoryWindow;
    } // retranslateUi

};

namespace Ui {
    class HistoryWindow: public Ui_HistoryWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_HISTORYWINDOW_H
