#include "models/reservationorder.h"
#include <QJsonObject>

ReservationOrder::ReservationOrder(QObject *parent)
    : QObject(parent)
    , m_orderId(0)
    , m_status(0)
    , m_totalFee(0.0)
    , m_paymentStatus(0)
{
}

ReservationOrder* ReservationOrder::fromJson(const QJsonObject &json, QObject *parent)
{
    ReservationOrder *order = new ReservationOrder(parent);
    
    order->m_orderId = json["order_id"].toInt();
    order->m_reservationCode = json["reservation_cod"].toString();
    order->m_status = json["status"].toInt();
    order->m_totalFee = json["total_fee"].toDouble();
    order->m_paymentStatus = json["payment_status"].toInt();
    
    QString startTimeStr = json["start_time"].toString();
    order->m_startTime = QDateTime::fromString(startTimeStr, Qt::ISODate);
    
    QString endTimeStr = json["end_time"].toString();
    order->m_endTime = QDateTime::fromString(endTimeStr, Qt::ISODate);
    
    return order;
}

