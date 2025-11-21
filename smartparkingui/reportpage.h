#ifndef REPORTPAGE_H
#define REPORTPAGE_H

#include <QWidget>

namespace Ui {
class ReportPage;
}

class ReportPage : public QWidget
{
    Q_OBJECT

public:
    explicit ReportPage(unsigned int lotId = 0, QWidget *parent = nullptr);
    ~ReportPage();

private slots:
    void on_btn_generate_clicked();
    void on_btn_export_clicked();
    void onReportFinished();

private:
    Ui::ReportPage *ui;
    unsigned int m_lotId;
    void showStatus(const QString &msg);
};

#endif // REPORTPAGE_H
