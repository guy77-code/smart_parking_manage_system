#ifndef RESERVATIONORDER_H
#define RESERVATIONORDER_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QJsonObject>

class ReservationOrder : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int orderId READ orderId NOTIFY orderIdChanged)
    Q_PROPERTY(QString reservationCode READ reservationCode NOTIFY reservationCodeChanged)
    Q_PROPERTY(int status READ status NOTIFY statusChanged)
    Q_PROPERTY(QDateTime startTime READ startTime NOTIFY startTimeChanged)
    Q_PROPERTY(QDateTime endTime READ endTime NOTIFY endTimeChanged)
    Q_PROPERTY(double totalFee READ totalFee NOTIFY totalFeeChanged)
    Q_PROPERTY(int paymentStatus READ paymentStatus NOTIFY paymentStatusChanged)

public:
    explicit ReservationOrder(QObject *parent = nullptr);

    int orderId() const { return m_orderId; }
    QString reservationCode() const { return m_reservationCode; }
    int status() const { return m_status; }
    QDateTime startTime() const { return m_startTime; }
    QDateTime endTime() const { return m_endTime; }
    double totalFee() const { return m_totalFee; }
    int paymentStatus() const { return m_paymentStatus; }

    static ReservationOrder* fromJson(const QJsonObject &json, QObject *parent = nullptr);

signals:
    void orderIdChanged();
    void reservationCodeChanged();
    void statusChanged();
    void startTimeChanged();
    void endTimeChanged();
    void totalFeeChanged();
    void paymentStatusChanged();

private:
    int m_orderId;
    QString m_reservationCode;
    int m_status;
    QDateTime m_startTime;
    QDateTime m_endTime;
    double m_totalFee;
    int m_paymentStatus;
};

#endif // RESERVATIONORDER_H

