#ifndef HISTORYWINDOW_H
#define HISTORYWINDOW_H

#include <QWidget>
#include <QTableWidget>
#include <QTableWidgetItem>  // ✅ 必须包含，否则 QTableWidgetItem 未定义
#include <QPushButton>
#include <QLabel>

namespace Ui {
class HistoryWindow;
}

class HistoryWindow : public QWidget
{
    Q_OBJECT

public:
    explicit HistoryWindow(uint userId, QWidget *parent = nullptr);
    ~HistoryWindow();

private:
    Ui::HistoryWindow *ui;
    uint m_userId;
    void loadHistory();
};

#endif // HISTORYWINDOW_H
