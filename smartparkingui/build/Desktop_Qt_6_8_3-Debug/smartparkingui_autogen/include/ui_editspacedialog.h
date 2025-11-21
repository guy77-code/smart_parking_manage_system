/********************************************************************************
** Form generated from reading UI file 'editspacedialog.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_EDITSPACEDIALOG_H
#define UI_EDITSPACEDIALOG_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QDialog>
#include <QtWidgets/QFormLayout>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QVBoxLayout>

QT_BEGIN_NAMESPACE

class Ui_EditSpaceDialog
{
public:
    QVBoxLayout *verticalLayout;
    QFormLayout *formLayout;
    QLabel *label_spaceId;
    QLabel *label_spaceIdValue;
    QLabel *label_status;
    QComboBox *combo_status;
    QLabel *label_note;
    QLineEdit *edit_note;
    QHBoxLayout *buttons;
    QSpacerItem *spacerLeft;
    QPushButton *btn_cancel;
    QPushButton *btn_save;

    void setupUi(QDialog *EditSpaceDialog)
    {
        if (EditSpaceDialog->objectName().isEmpty())
            EditSpaceDialog->setObjectName("EditSpaceDialog");
        EditSpaceDialog->resize(520, 340);
        verticalLayout = new QVBoxLayout(EditSpaceDialog);
        verticalLayout->setObjectName("verticalLayout");
        formLayout = new QFormLayout();
        formLayout->setObjectName("formLayout");
        label_spaceId = new QLabel(EditSpaceDialog);
        label_spaceId->setObjectName("label_spaceId");

        formLayout->setWidget(0, QFormLayout::LabelRole, label_spaceId);

        label_spaceIdValue = new QLabel(EditSpaceDialog);
        label_spaceIdValue->setObjectName("label_spaceIdValue");

        formLayout->setWidget(0, QFormLayout::FieldRole, label_spaceIdValue);

        label_status = new QLabel(EditSpaceDialog);
        label_status->setObjectName("label_status");

        formLayout->setWidget(1, QFormLayout::LabelRole, label_status);

        combo_status = new QComboBox(EditSpaceDialog);
        combo_status->addItem(QString());
        combo_status->addItem(QString());
        combo_status->addItem(QString());
        combo_status->addItem(QString());
        combo_status->setObjectName("combo_status");

        formLayout->setWidget(1, QFormLayout::FieldRole, combo_status);

        label_note = new QLabel(EditSpaceDialog);
        label_note->setObjectName("label_note");

        formLayout->setWidget(2, QFormLayout::LabelRole, label_note);

        edit_note = new QLineEdit(EditSpaceDialog);
        edit_note->setObjectName("edit_note");

        formLayout->setWidget(2, QFormLayout::FieldRole, edit_note);


        verticalLayout->addLayout(formLayout);

        buttons = new QHBoxLayout();
        buttons->setObjectName("buttons");
        spacerLeft = new QSpacerItem(0, 0, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        buttons->addItem(spacerLeft);

        btn_cancel = new QPushButton(EditSpaceDialog);
        btn_cancel->setObjectName("btn_cancel");

        buttons->addWidget(btn_cancel);

        btn_save = new QPushButton(EditSpaceDialog);
        btn_save->setObjectName("btn_save");

        buttons->addWidget(btn_save);


        verticalLayout->addLayout(buttons);


        retranslateUi(EditSpaceDialog);

        QMetaObject::connectSlotsByName(EditSpaceDialog);
    } // setupUi

    void retranslateUi(QDialog *EditSpaceDialog)
    {
        EditSpaceDialog->setWindowTitle(QCoreApplication::translate("EditSpaceDialog", "\344\277\256\346\224\271\350\275\246\344\275\215", nullptr));
        label_spaceId->setText(QCoreApplication::translate("EditSpaceDialog", "\350\275\246\344\275\215ID\357\274\232", nullptr));
        label_spaceIdValue->setText(QCoreApplication::translate("EditSpaceDialog", "\342\200\224", nullptr));
        label_status->setText(QCoreApplication::translate("EditSpaceDialog", "\347\212\266\346\200\201\357\274\232", nullptr));
        combo_status->setItemText(0, QCoreApplication::translate("EditSpaceDialog", "available", nullptr));
        combo_status->setItemText(1, QCoreApplication::translate("EditSpaceDialog", "occupied", nullptr));
        combo_status->setItemText(2, QCoreApplication::translate("EditSpaceDialog", "reserved", nullptr));
        combo_status->setItemText(3, QCoreApplication::translate("EditSpaceDialog", "disabled", nullptr));

        label_note->setText(QCoreApplication::translate("EditSpaceDialog", "\345\244\207\346\263\250\357\274\232", nullptr));
        btn_cancel->setText(QCoreApplication::translate("EditSpaceDialog", "\345\217\226\346\266\210", nullptr));
        btn_save->setText(QCoreApplication::translate("EditSpaceDialog", "\344\277\235\345\255\230", nullptr));
    } // retranslateUi

};

namespace Ui {
    class EditSpaceDialog: public Ui_EditSpaceDialog {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_EDITSPACEDIALOG_H
