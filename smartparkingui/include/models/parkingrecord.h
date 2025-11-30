#ifndef PARKINGRECORD_H
#define PARKINGRECORD_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QJsonObject>

class ParkingRecord : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int recordId READ recordId NOTIFY recordIdChanged)
    Q_PROPERTY(int userId READ userId NOTIFY userIdChanged)
    Q_PROPERTY(int vehicleId READ vehicleId NOTIFY vehicleIdChanged)
    Q_PROPERTY(QString licensePlate READ licensePlate NOTIFY licensePlateChanged)
    Q_PROPERTY(QString spaceNumber READ spaceNumber NOTIFY spaceNumberChanged)
    Q_PROPERTY(QString lotName READ lotName NOTIFY lotNameChanged)
    Q_PROPERTY(QDateTime entryTime READ entryTime NOTIFY entryTimeChanged)
    Q_PROPERTY(QDateTime exitTime READ exitTime NOTIFY exitTimeChanged)
    Q_PROPERTY(double durationHours READ durationHours NOTIFY durationHoursChanged)
    Q_PROPERTY(double totalFee READ totalFee NOTIFY totalFeeChanged)
    Q_PROPERTY(bool isViolation READ isViolation NOTIFY isViolationChanged)
    Q_PROPERTY(double violationFee READ violationFee NOTIFY violationFeeChanged)
    Q_PROPERTY(QString paymentUrl READ paymentUrl NOTIFY paymentUrlChanged)
    Q_PROPERTY(int recordStatus READ recordStatus NOTIFY recordStatusChanged)

public:
    explicit ParkingRecord(QObject *parent = nullptr);

    int recordId() const { return m_recordId; }
    int userId() const { return m_userId; }
    int vehicleId() const { return m_vehicleId; }
    QString licensePlate() const { return m_licensePlate; }
    QString spaceNumber() const { return m_spaceNumber; }
    QString lotName() const { return m_lotName; }
    QDateTime entryTime() const { return m_entryTime; }
    QDateTime exitTime() const { return m_exitTime; }
    double durationHours() const { return m_durationHours; }
    double totalFee() const { return m_totalFee; }
    bool isViolation() const { return m_isViolation; }
    double violationFee() const { return m_violationFee; }
    QString paymentUrl() const { return m_paymentUrl; }
    int recordStatus() const { return m_recordStatus; }

    static ParkingRecord* fromJson(const QJsonObject &json, QObject *parent = nullptr);

signals:
    void recordIdChanged();
    void userIdChanged();
    void vehicleIdChanged();
    void licensePlateChanged();
    void spaceNumberChanged();
    void lotNameChanged();
    void entryTimeChanged();
    void exitTimeChanged();
    void durationHoursChanged();
    void totalFeeChanged();
    void isViolationChanged();
    void violationFeeChanged();
    void paymentUrlChanged();
    void recordStatusChanged();

private:
    int m_recordId;
    int m_userId;
    int m_vehicleId;
    QString m_licensePlate;
    QString m_spaceNumber;
    QString m_lotName;
    QDateTime m_entryTime;
    QDateTime m_exitTime;
    double m_durationHours;
    double m_totalFee;
    bool m_isViolation;
    double m_violationFee;
    QString m_paymentUrl;
    int m_recordStatus;
};

#endif // PARKINGRECORD_H

