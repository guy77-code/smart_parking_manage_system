/********************************************************************************
** Form generated from reading UI file 'userpage.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_USERPAGE_H
#define UI_USERPAGE_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QFrame>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_UserPage
{
public:
    QVBoxLayout *verticalLayout;
    QPushButton *btn_logout;
    QFrame *headerFrame;
    QHBoxLayout *headerLayout;
    QLabel *label_status;
    QSpacerItem *horizontalSpacer;
    QPushButton *btn_refresh;
    QFrame *actionFrame;
    QHBoxLayout *actionLayout;
    QPushButton *btn_park;
    QPushButton *btn_leave;
    QSpacerItem *actionSpacer;
    QGroupBox *group_reservation;
    QVBoxLayout *reservationLayout;
    QLabel *label_reservation;
    QPushButton *btn_reserve;
    QGroupBox *group_order;
    QVBoxLayout *orderLayout;
    QLabel *label_order;
    QHBoxLayout *orderButtonLayout;
    QPushButton *btn_view_history;
    QSpacerItem *orderButtonSpacer;

    void setupUi(QWidget *UserPage)
    {
        if (UserPage->objectName().isEmpty())
            UserPage->setObjectName("UserPage");
        UserPage->resize(700, 480);
        UserPage->setMinimumSize(QSize(700, 480));
        verticalLayout = new QVBoxLayout(UserPage);
        verticalLayout->setObjectName("verticalLayout");
        btn_logout = new QPushButton(UserPage);
        btn_logout->setObjectName("btn_logout");

        verticalLayout->addWidget(btn_logout, 0, Qt::AlignmentFlag::AlignLeft);

        headerFrame = new QFrame(UserPage);
        headerFrame->setObjectName("headerFrame");
        headerFrame->setFrameShape(QFrame::Shape::StyledPanel);
        headerLayout = new QHBoxLayout(headerFrame);
        headerLayout->setObjectName("headerLayout");
        label_status = new QLabel(headerFrame);
        label_status->setObjectName("label_status");
        QFont font;
        font.setPointSize(12);
        font.setBold(true);
        label_status->setFont(font);

        headerLayout->addWidget(label_status);

        horizontalSpacer = new QSpacerItem(0, 0, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        headerLayout->addItem(horizontalSpacer);

        btn_refresh = new QPushButton(headerFrame);
        btn_refresh->setObjectName("btn_refresh");

        headerLayout->addWidget(btn_refresh);


        verticalLayout->addWidget(headerFrame);

        actionFrame = new QFrame(UserPage);
        actionFrame->setObjectName("actionFrame");
        actionLayout = new QHBoxLayout(actionFrame);
        actionLayout->setObjectName("actionLayout");
        btn_park = new QPushButton(actionFrame);
        btn_park->setObjectName("btn_park");
        btn_park->setMinimumSize(QSize(120, 40));

        actionLayout->addWidget(btn_park);

        btn_leave = new QPushButton(actionFrame);
        btn_leave->setObjectName("btn_leave");
        btn_leave->setMinimumSize(QSize(120, 40));

        actionLayout->addWidget(btn_leave);

        actionSpacer = new QSpacerItem(0, 0, QSizePolicy::Policy::Minimum, QSizePolicy::Policy::Expanding);

        actionLayout->addItem(actionSpacer);


        verticalLayout->addWidget(actionFrame);

        group_reservation = new QGroupBox(UserPage);
        group_reservation->setObjectName("group_reservation");
        reservationLayout = new QVBoxLayout(group_reservation);
        reservationLayout->setObjectName("reservationLayout");
        label_reservation = new QLabel(group_reservation);
        label_reservation->setObjectName("label_reservation");

        reservationLayout->addWidget(label_reservation);

        btn_reserve = new QPushButton(group_reservation);
        btn_reserve->setObjectName("btn_reserve");
        btn_reserve->setMaximumSize(QSize(140, 30));

        reservationLayout->addWidget(btn_reserve);


        verticalLayout->addWidget(group_reservation);

        group_order = new QGroupBox(UserPage);
        group_order->setObjectName("group_order");
        orderLayout = new QVBoxLayout(group_order);
        orderLayout->setObjectName("orderLayout");
        label_order = new QLabel(group_order);
        label_order->setObjectName("label_order");

        orderLayout->addWidget(label_order);

        orderButtonLayout = new QHBoxLayout();
        orderButtonLayout->setObjectName("orderButtonLayout");
        btn_view_history = new QPushButton(group_order);
        btn_view_history->setObjectName("btn_view_history");

        orderButtonLayout->addWidget(btn_view_history);

        orderButtonSpacer = new QSpacerItem(0, 0, QSizePolicy::Policy::Minimum, QSizePolicy::Policy::Expanding);

        orderButtonLayout->addItem(orderButtonSpacer);


        orderLayout->addLayout(orderButtonLayout);


        verticalLayout->addWidget(group_order);


        retranslateUi(UserPage);

        QMetaObject::connectSlotsByName(UserPage);
    } // setupUi

    void retranslateUi(QWidget *UserPage)
    {
        btn_logout->setText(QCoreApplication::translate("UserPage", "\351\200\200\345\207\272\347\231\273\345\275\225", nullptr));
        label_status->setText(QCoreApplication::translate("UserPage", "\345\212\240\350\275\275\344\270\255\342\200\246", nullptr));
        btn_refresh->setText(QCoreApplication::translate("UserPage", "\345\210\267\346\226\260", nullptr));
        btn_park->setText(QCoreApplication::translate("UserPage", "\345\201\234\350\275\246", nullptr));
        btn_leave->setText(QCoreApplication::translate("UserPage", "\347\246\273\345\274\200", nullptr));
        group_reservation->setTitle(QCoreApplication::translate("UserPage", "\351\242\204\350\256\242\344\277\241\346\201\257", nullptr));
        label_reservation->setText(QCoreApplication::translate("UserPage", "\346\255\243\345\234\250\345\212\240\350\275\275\351\242\204\350\256\242\344\277\241\346\201\257\342\200\246", nullptr));
        btn_reserve->setText(QCoreApplication::translate("UserPage", "\351\242\204\350\256\242", nullptr));
        group_order->setTitle(QCoreApplication::translate("UserPage", "\350\256\242\345\215\225\344\277\241\346\201\257", nullptr));
        label_order->setText(QCoreApplication::translate("UserPage", "\346\255\243\345\234\250\345\212\240\350\275\275\350\256\242\345\215\225\344\277\241\346\201\257\342\200\246", nullptr));
        btn_view_history->setText(QCoreApplication::translate("UserPage", "\346\237\245\347\234\213\346\224\257\344\273\230\344\277\241\346\201\257\345\222\214\345\216\206\345\217\262\345\201\234\350\275\246\344\277\241\346\201\257", nullptr));
        (void)UserPage;
    } // retranslateUi

};

namespace Ui {
    class UserPage: public Ui_UserPage {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_USERPAGE_H
