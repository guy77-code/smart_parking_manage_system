/********************************************************************************
** Form generated from reading UI file 'reportpage.ui'
**
** Created by: Qt User Interface Compiler version 6.8.3
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_REPORTPAGE_H
#define UI_REPORTPAGE_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QComboBox>
#include <QtWidgets/QHBoxLayout>
#include <QtWidgets/QLabel>
#include <QtWidgets/QListView>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpacerItem>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QSplitter>
#include <QtWidgets/QTextEdit>
#include <QtWidgets/QVBoxLayout>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_ReportPage
{
public:
    QVBoxLayout *verticalLayout;
    QWidget *topBar;
    QHBoxLayout *topBarLayout;
    QLabel *label_title;
    QSpacerItem *topSpacer;
    QComboBox *combo_reportType;
    QSpinBox *spin_year;
    QPushButton *btn_generate;
    QPushButton *btn_export;
    QSplitter *mainSplitter;
    QWidget *leftPanel;
    QVBoxLayout *leftLayout;
    QListView *list_reportSections;
    QWidget *rightPanel;
    QVBoxLayout *rightLayout;
    QWidget *chartContainer;
    QTextEdit *text_reportSummary;

    void setupUi(QWidget *ReportPage)
    {
        if (ReportPage->objectName().isEmpty())
            ReportPage->setObjectName("ReportPage");
        ReportPage->resize(1100, 700);
        verticalLayout = new QVBoxLayout(ReportPage);
        verticalLayout->setObjectName("verticalLayout");
        topBar = new QWidget(ReportPage);
        topBar->setObjectName("topBar");
        topBarLayout = new QHBoxLayout(topBar);
        topBarLayout->setObjectName("topBarLayout");
        topBarLayout->setContentsMargins(0, 0, 0, 0);
        label_title = new QLabel(topBar);
        label_title->setObjectName("label_title");
        QFont font;
        font.setPointSize(18);
        font.setBold(true);
        label_title->setFont(font);

        topBarLayout->addWidget(label_title);

        topSpacer = new QSpacerItem(0, 0, QSizePolicy::Policy::Expanding, QSizePolicy::Policy::Minimum);

        topBarLayout->addItem(topSpacer);

        combo_reportType = new QComboBox(topBar);
        combo_reportType->addItem(QString());
        combo_reportType->addItem(QString());
        combo_reportType->setObjectName("combo_reportType");

        topBarLayout->addWidget(combo_reportType);

        spin_year = new QSpinBox(topBar);
        spin_year->setObjectName("spin_year");
        spin_year->setMinimum(2000);
        spin_year->setMaximum(2100);
        spin_year->setValue(2025);

        topBarLayout->addWidget(spin_year);

        btn_generate = new QPushButton(topBar);
        btn_generate->setObjectName("btn_generate");

        topBarLayout->addWidget(btn_generate);

        btn_export = new QPushButton(topBar);
        btn_export->setObjectName("btn_export");

        topBarLayout->addWidget(btn_export);


        verticalLayout->addWidget(topBar);

        mainSplitter = new QSplitter(ReportPage);
        mainSplitter->setObjectName("mainSplitter");
        mainSplitter->setOrientation(Qt::Horizontal);
        leftPanel = new QWidget(mainSplitter);
        leftPanel->setObjectName("leftPanel");
        leftLayout = new QVBoxLayout(leftPanel);
        leftLayout->setObjectName("leftLayout");
        leftLayout->setContentsMargins(0, 0, 0, 0);
        list_reportSections = new QListView(leftPanel);
        list_reportSections->setObjectName("list_reportSections");

        leftLayout->addWidget(list_reportSections);

        mainSplitter->addWidget(leftPanel);
        rightPanel = new QWidget(mainSplitter);
        rightPanel->setObjectName("rightPanel");
        rightLayout = new QVBoxLayout(rightPanel);
        rightLayout->setObjectName("rightLayout");
        rightLayout->setContentsMargins(0, 0, 0, 0);
        chartContainer = new QWidget(rightPanel);
        chartContainer->setObjectName("chartContainer");

        rightLayout->addWidget(chartContainer);

        text_reportSummary = new QTextEdit(rightPanel);
        text_reportSummary->setObjectName("text_reportSummary");
        text_reportSummary->setReadOnly(true);

        rightLayout->addWidget(text_reportSummary);

        mainSplitter->addWidget(rightPanel);

        verticalLayout->addWidget(mainSplitter);


        retranslateUi(ReportPage);

        QMetaObject::connectSlotsByName(ReportPage);
    } // setupUi

    void retranslateUi(QWidget *ReportPage)
    {
        ReportPage->setWindowTitle(QCoreApplication::translate("ReportPage", "\346\212\245\350\241\250\344\270\216\345\233\276\350\241\250", nullptr));
        label_title->setText(QCoreApplication::translate("ReportPage", "\346\212\245\350\241\250\344\270\255\345\277\203", nullptr));
        combo_reportType->setItemText(0, QCoreApplication::translate("ReportPage", "monthly", nullptr));
        combo_reportType->setItemText(1, QCoreApplication::translate("ReportPage", "annual", nullptr));

        btn_generate->setText(QCoreApplication::translate("ReportPage", "\347\224\237\346\210\220\346\212\245\350\241\250", nullptr));
        btn_export->setText(QCoreApplication::translate("ReportPage", "\345\257\274\345\207\272 PDF/CSV", nullptr));
    } // retranslateUi

};

namespace Ui {
    class ReportPage: public Ui_ReportPage {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_REPORTPAGE_H
