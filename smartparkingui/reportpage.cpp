#include "reportpage.h"
#include "ui_reportpage.h"
#include "networkmanager.h"
#include <QJsonDocument>
#include <QMessageBox>

ReportPage::ReportPage(unsigned int lotId, QWidget *parent) :
    QWidget(parent),
    ui(new Ui::ReportPage),
    m_lotId(lotId)
{
    ui->setupUi(this);
    this->resize(1100, 700);

    // 默认为当前年
    ui->spin_year->setValue(QDate::currentDate().year());

    connect(ui->btn_generate, &QPushButton::clicked, this, &ReportPage::on_btn_generate_clicked);
    connect(ui->btn_export, &QPushButton::clicked, this, &ReportPage::on_btn_export_clicked);
}

ReportPage::~ReportPage()
{
    delete ui;
}

void ReportPage::showStatus(const QString &msg)
{
    // 显示在文本区域顶部或状态条
    ui->text_reportSummary->setPlainText(msg);
}

void ReportPage::on_btn_generate_clicked()
{
    QString type = ui->combo_reportType->currentText();
    int year = ui->spin_year->value();

    QUrl url(QString("http://127.0.0.1:8080/api/v1/admin/report?lot_id=%1&type=%2&year=%3")
                 .arg(m_lotId).arg(type).arg(year));
    NetworkManager *net = NetworkManager::instance();
    QNetworkReply *reply = net->get(url);
    connect(reply, &QNetworkReply::finished, this, &ReportPage::onReportFinished);

    showStatus("正在生成报表...");
}

void ReportPage::onReportFinished()
{
    QNetworkReply *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;
    QByteArray resp = reply->readAll();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        showStatus("生成失败: " + reply->errorString());
        return;
    }

    QJsonDocument doc = QJsonDocument::fromJson(resp);
    QJsonObject obj = doc.object();
    if (!obj.contains("report")) {
        showStatus("返回数据格式不包含 report 字段");
        return;
    }
    QJsonObject report = obj["report"].toObject();

    // 简单展示部分字段到 text_edit（你可以解析并用 QChart 显示图表）
    QString summary;
    summary += QString("报告类型: %1\n").arg(report["report_type"].toString());
    summary += QString("时间段: %1\n").arg(report["period"].toString());
    summary += QString("生成时间: %1\n\n").arg(report["generated_at"].toString());
    summary += "停车统计:\n";
    QJsonObject parkingStats = report["parking_statistics"].toObject();
    summary += QString("  总停车次数: %1\n").arg(parkingStats["total_parkings"].toVariant().toString());
    summary += QString("  平均停车时长(小时): %1\n\n").arg(parkingStats["avg_parking_hours"].toDouble());

    summary += "违规统计:\n";
    QJsonObject v = report["violation_statistics"].toObject();
    summary += QString("  总违规: %1\n").arg(v["total_violations"].toVariant().toString());
    summary += QString("  已处理: %1\n\n").arg(v["processed_violations"].toVariant().toString());

    summary += "收入统计:\n";
    QJsonObject r = report["revenue_statistics"].toObject();
    summary += QString("  停车收入: %1\n  罚款收入: %2\n  总收入: %3\n")
                   .arg(r["parking_income"].toDouble())
                   .arg(r["fine_income"].toDouble())
                   .arg(r["total_income"].toDouble());

    ui->text_reportSummary->setPlainText(summary);
    QMessageBox::information(this, "生成完成", "报表数据已加载。你可以使用导出按钮生成 PDF/CSV（需在前端实现导出功能）");
}

void ReportPage::on_btn_export_clicked()
{
    // 导出逻辑依赖你的项目（例如将 ui->text_reportSummary 转为 PDF、或将 report JSON 保存为 CSV）。
    QMessageBox::information(this, "导出", "导出功能需要在前端实现（示例：生成 PDF 或 CSV 并保存）。");
}
