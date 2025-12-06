#ifndef MESSAGEBOXHELPER_H
#define MESSAGEBOXHELPER_H

#include <QObject>
#include <QMessageBox>

class MessageBoxHelper : public QObject
{
    Q_OBJECT

public:
    explicit MessageBoxHelper(QObject *parent = nullptr);

    // 显示信息对话框
    Q_INVOKABLE int showInformation(const QString &title, const QString &text, 
                                     QMessageBox::StandardButtons buttons = QMessageBox::Ok);
    
    // 显示警告对话框
    Q_INVOKABLE int showWarning(const QString &title, const QString &text,
                                QMessageBox::StandardButtons buttons = QMessageBox::Ok);
    
    // 显示错误对话框
    Q_INVOKABLE int showError(const QString &title, const QString &text,
                              QMessageBox::StandardButtons buttons = QMessageBox::Ok);
    
    // 显示问题对话框（带确认和取消按钮）
    Q_INVOKABLE int showQuestion(const QString &title, const QString &text,
                                 QMessageBox::StandardButtons buttons = QMessageBox::Yes | QMessageBox::No);

signals:
    void dialogClosed(int result);
};

#endif // MESSAGEBOXHELPER_H

