/********************************************************************************
** Form generated from reading UI file 'systemadminpage.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_SYSTEMADMINPAGE_H
#define UI_SYSTEMADMINPAGE_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QHeaderView>
#include <QtWidgets/QLabel>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QTableWidget>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_SystemAdminPage
{
public:
    QVBoxLayout *verticalLayout_root;
    QLabel *label_title;
    QTableWidget *table_parkingLots;
    QHBoxLayout *horizontalLayout_buttons;
    QPushButton *btn_refresh;
    QPushButton *btn_add;
    QPushButton *btn_delete;
    QPushButton *btn_queryViolation;
    QSpacerItem *spacer_buttons;
    QPushButton *btn_logout;

    void setupUi(QWidget *SystemAdminPage)
    {
        if (SystemAdminPage->objectName().isEmpty())
            SystemAdminPage->setObjectName("SystemAdminPage");
        verticalLayout_root = new QVBoxLayout(SystemAdminPage);
        verticalLayout_root->setObjectName("verticalLayout_root");
        label_title = new QLabel(SystemAdminPage);
        label_title->setObjectName("label_title");
        label_title->setAlignment(Qt::AlignCenter);
        label_title->setStyleSheet(QString::fromUtf8("font-size: 24px; font-weight: bold; margin: 10px;"));

        verticalLayout_root->addWidget(label_title);

        table_parkingLots = new QTableWidget(SystemAdminPage);
        table_parkingLots->setObjectName("table_parkingLots");

        verticalLayout_root->addWidget(table_parkingLots);

        horizontalLayout_buttons = new QHBoxLayout();
        horizontalLayout_buttons->setObjectName("horizontalLayout_buttons");
        btn_refresh = new QPushButton(SystemAdminPage);
        btn_refresh->setObjectName("btn_refresh");
        btn_refresh->setMinimumWidth(100);

        horizontalLayout_buttons->addWidget(btn_refresh);

        btn_add = new QPushButton(SystemAdminPage);
        btn_add->setObjectName("btn_add");

        horizontalLayout_buttons->addWidget(btn_add);

        btn_delete = new QPushButton(SystemAdminPage);
        btn_delete->setObjectName("btn_delete");

        horizontalLayout_buttons->addWidget(btn_delete);

        btn_queryViolation = new QPushButton(SystemAdminPage);
        btn_queryViolation->setObjectName("btn_queryViolation");

        horizontalLayout_buttons->addWidget(btn_queryViolation);

        spacer_buttons = new QSpacerItem(0, 0, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        horizontalLayout_buttons->addItem(spacer_buttons);

        btn_logout = new QPushButton(SystemAdminPage);
        btn_logout->setObjectName("btn_logout");
        btn_logout->setStyleSheet(QString::fromUtf8("background-color:#e57373;color:white;border-radius:6px;padding:6px 12px;"));

        horizontalLayout_buttons->addWidget(btn_logout);


        verticalLayout_root->addLayout(horizontalLayout_buttons);


        retranslateUi(SystemAdminPage);

        QMetaObject::connectSlotsByName(SystemAdminPage);
    } // setupUi

    void retranslateUi(QWidget *SystemAdminPage)
    {
        SystemAdminPage->setWindowTitle(QCoreApplication::translate("SystemAdminPage", "\347\263\273\347\273\237\347\256\241\347\220\206\345\221\230\351\241\265\351\235\242", nullptr));
        label_title->setText(QCoreApplication::translate("SystemAdminPage", "\347\263\273\347\273\237\347\256\241\347\220\206\345\221\230\345\220\216\345\217\260\347\256\241\347\220\206", nullptr));
        btn_refresh->setText(QCoreApplication::translate("SystemAdminPage", "\360\237\224\204 \345\210\267\346\226\260", nullptr));
        btn_add->setText(QCoreApplication::translate("SystemAdminPage", "\342\236\225 \346\267\273\345\212\240\345\201\234\350\275\246\345\234\272", nullptr));
        btn_delete->setText(QCoreApplication::translate("SystemAdminPage", "\360\237\227\221 \345\210\240\351\231\244\345\201\234\350\275\246\345\234\272", nullptr));
        btn_queryViolation->setText(QCoreApplication::translate("SystemAdminPage", "\360\237\223\212 \346\237\245\350\257\242\350\277\235\350\247\204\346\225\260\346\215\256", nullptr));
        btn_logout->setText(QCoreApplication::translate("SystemAdminPage", "\360\237\232\252 \351\200\200\345\207\272\347\231\273\345\275\225", nullptr));
    } // retranslateUi

};

namespace Ui {
    class SystemAdminPage: public Ui_SystemAdminPage {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_SYSTEMADMINPAGE_H
