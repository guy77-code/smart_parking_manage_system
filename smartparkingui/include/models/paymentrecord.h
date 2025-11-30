#ifndef PAYMENTRECORD_H
#define PAYMENTRECORD_H

#include <QObject>
#include <QString>
#include <QDateTime>
#include <QJsonObject>

class PaymentRecord : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int paymentId READ paymentId NOTIFY paymentIdChanged)
    Q_PROPERTY(int orderId READ orderId NOTIFY orderIdChanged)
    Q_PROPERTY(double amount READ amount NOTIFY amountChanged)
    Q_PROPERTY(QString method READ method NOTIFY methodChanged)
    Q_PROPERTY(int paymentStatus READ paymentStatus NOTIFY paymentStatusChanged)
    Q_PROPERTY(QDateTime payTime READ payTime NOTIFY payTimeChanged)
    Q_PROPERTY(QString transactionNo READ transactionNo NOTIFY transactionNoChanged)

public:
    explicit PaymentRecord(QObject *parent = nullptr);

    int paymentId() const { return m_paymentId; }
    int orderId() const { return m_orderId; }
    double amount() const { return m_amount; }
    QString method() const { return m_method; }
    int paymentStatus() const { return m_paymentStatus; }
    QDateTime payTime() const { return m_payTime; }
    QString transactionNo() const { return m_transactionNo; }

    static PaymentRecord* fromJson(const QJsonObject &json, QObject *parent = nullptr);

signals:
    void paymentIdChanged();
    void orderIdChanged();
    void amountChanged();
    void methodChanged();
    void paymentStatusChanged();
    void payTimeChanged();
    void transactionNoChanged();

private:
    int m_paymentId;
    int m_orderId;
    double m_amount;
    QString m_method;
    int m_paymentStatus;
    QDateTime m_payTime;
    QString m_transactionNo;
};

#endif // PAYMENTRECORD_H

