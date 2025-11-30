#include "models/paymentrecord.h"
#include <QJsonObject>

PaymentRecord::PaymentRecord(QObject *parent)
    : QObject(parent)
    , m_paymentId(0)
    , m_orderId(0)
    , m_amount(0.0)
    , m_paymentStatus(0)
{
}

PaymentRecord* PaymentRecord::fromJson(const QJsonObject &json, QObject *parent)
{
    PaymentRecord *record = new PaymentRecord(parent);
    
    record->m_paymentId = json["payment_id"].toInt();
    record->m_orderId = json["order_id"].toInt();
    record->m_amount = json["amount"].toDouble();
    record->m_method = json["method"].toString();
    record->m_paymentStatus = json["payment_status"].toInt();
    record->m_transactionNo = json["transaction_no"].toString();
    
    if (json.contains("pay_time") && !json["pay_time"].isNull()) {
        QString payTimeStr = json["pay_time"].toString();
        record->m_payTime = QDateTime::fromString(payTimeStr, Qt::ISODate);
    }
    
    return record;
}

