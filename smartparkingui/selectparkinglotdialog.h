#ifndef SELECTPARKINGLOTDIALOG_H
#define SELECTPARKINGLOTDIALOG_H

#include <QDialog>

namespace Ui {
class SelectParkingLotDialog;
}

class SelectParkingLotDialog : public QDialog
{
    Q_OBJECT

public:
    explicit SelectParkingLotDialog(QWidget *parent = nullptr);
    ~SelectParkingLotDialog();

    uint selectedLotId() const;
    uint selectedVehicleId() const;

private slots:
    void loadParkingLots();
    void onOkClicked();

private:
    Ui::SelectParkingLotDialog *ui;
    uint m_selectedLotId = 0;
    uint m_selectedVehicleId = 0;
};

#endif // SELECTPARKINGLOTDIALOG_H
