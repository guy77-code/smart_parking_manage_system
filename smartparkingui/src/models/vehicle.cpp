#include "models/vehicle.h"
#include <QJsonObject>

Vehicle::Vehicle(QObject *parent)
    : QObject(parent)
    , m_vehicleId(0)
{
}

Vehicle* Vehicle::fromJson(const QJsonObject &json, QObject *parent)
{
    Vehicle *vehicle = new Vehicle(parent);
    
    vehicle->m_vehicleId = json["vehicle_id"].toInt();
    vehicle->m_licensePlate = json["license_plate"].toString();
    vehicle->m_brand = json["brand"].toString();
    vehicle->m_model = json["model"].toString();
    vehicle->m_color = json["color"].toString();
    
    return vehicle;
}

