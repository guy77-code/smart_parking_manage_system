#include "models/violationrecord.h"
#include <QJsonObject>

ViolationRecord::ViolationRecord(QObject *parent)
    : QObject(parent)
    , m_violationId(0)
    , m_fineAmount(0.0)
    , m_status(0)
{
}

ViolationRecord* ViolationRecord::fromJson(const QJsonObject &json, QObject *parent)
{
    ViolationRecord *record = new ViolationRecord(parent);
    
    record->m_violationId = json["violation_id"].toInt();
    record->m_violationType = json["violation_type"].toString();
    record->m_fineAmount = json["fine_amount"].toDouble();
    record->m_status = json["status"].toInt();
    record->m_description = json["description"].toString();
    
    QString violationTimeStr = json["violation_time"].toString();
    record->m_violationTime = QDateTime::fromString(violationTimeStr, Qt::ISODate);
    
    return record;
}

