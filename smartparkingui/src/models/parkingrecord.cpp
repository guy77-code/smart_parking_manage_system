#include "models/parkingrecord.h"
#include <QJsonObject>
#include <QJsonValue>

ParkingRecord::ParkingRecord(QObject *parent)
    : QObject(parent)
    , m_recordId(0)
    , m_userId(0)
    , m_vehicleId(0)
    , m_durationHours(0.0)
    , m_totalFee(0.0)
    , m_isViolation(false)
    , m_violationFee(0.0)
    , m_recordStatus(0)
{
}

ParkingRecord* ParkingRecord::fromJson(const QJsonObject &json, QObject *parent)
{
    ParkingRecord *record = new ParkingRecord(parent);
    
    record->m_recordId = json["record_id"].toInt();
    record->m_userId = json["user_id"].toInt();
    record->m_vehicleId = json["vehicle_id"].toInt();
    
    // Extract vehicle info
    QJsonObject vehicle = json["vehicle"].toObject();
    record->m_licensePlate = vehicle["license_plate"].toString();
    
    // Extract space info
    QJsonObject space = json["space"].toObject();
    record->m_spaceNumber = space["space_number"].toString();
    
    // Extract lot info
    QJsonObject lot = json["lot"].toObject();
    record->m_lotName = lot["name"].toString();
    
    // Parse entry time
    QString entryTimeStr = json["entry_time"].toString();
    record->m_entryTime = QDateTime::fromString(entryTimeStr, Qt::ISODate);
    
    // Parse exit time (may be null)
    if (json.contains("exit_time") && !json["exit_time"].isNull()) {
        QString exitTimeStr = json["exit_time"].toString();
        record->m_exitTime = QDateTime::fromString(exitTimeStr, Qt::ISODate);
    }
    
    record->m_durationHours = json["duration_hours"].toDouble();
    record->m_totalFee = json["total_fee"].toDouble();
    record->m_isViolation = json["is_violation"].toBool();
    record->m_violationFee = json["violation_fee"].toDouble();
    record->m_paymentUrl = json["payment_url"].toString();
    record->m_recordStatus = json["record_status"].toInt();
    
    return record;
}

